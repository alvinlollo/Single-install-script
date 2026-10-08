#!/usr/bin/bash

set -euo pipefail

# Detect fish shell and ask user to switch to bash (bash-only syntax)
if [ -n "${FISH_VERSION:-}" ] || case "${SHELL:-}" in *fish*) ;; *) false ;; esac; then
  echo "Warning: fish shell detected."
  echo "This script is written for bash and may have syntax issues under fish."
  echo "Please switch to bash first and re-run it, e.g.: bash $0"
  if [ -t 0 ] && [ -e /dev/tty ]; then
    read -r -p "Press Enter to continue anyway, or Ctrl+C to cancel..." </dev/tty || true
  fi
fi

# Secure Boot setup only applies to UEFI systems (meaningless on BIOS/CSM)
if [ ! -d /sys/firmware/efi ]; then
  echo "error: this system is not booted in UEFI mode (/sys/firmware/efi is missing)." >&2
  echo "Secure Boot setup does not apply to BIOS/CSM machines. Aborting." >&2
  exit 1
fi

if ! command -v pacman >/dev/null; then
  echo "error: pacman not found. This script only supports Arch-based systems." >&2
  exit 1
fi

# Install prerequisites
sudo pacman -S --needed --noconfirm efibootmgr sbsigntools mokutil sbctl grub

# Fail early if the toolchain is still missing (do not touch keys otherwise)
if ! command -v sbctl >/dev/null; then
  echo "error: sbctl is not available after installation. Install it manually and re-run." >&2
  exit 1
fi

# Candidate sign targets. GRUB's path and the kernel image name vary by
# machine, so every path is checked before signing instead of trusted blindly.
SIGN_TARGETS=(
  /boot/EFI/BOOT/BOOTX64.EFI
  /boot/grub/x86_64-efi/core.efi
  /boot/grub/x86_64-efi/grub.efi
  /boot/vmlinuz-linux
)

missing=0
for target in "${SIGN_TARGETS[@]}"; do
  if [ ! -e "$target" ]; then
    echo "warning: $target does not exist on this machine, skipping" >&2
    missing=$((missing + 1))
  fi
done

if [ "$missing" -eq "${#SIGN_TARGETS[@]}" ]; then
  echo "error: none of the expected boot files exist; refusing to continue." >&2
  echo "Adjust SIGN_TARGETS for this machine and re-run." >&2
  exit 1
fi

sudo sbctl create-keys

for target in "${SIGN_TARGETS[@]}"; do
  if [ -e "$target" ]; then
    sudo sbctl sign -s "$target"
  fi
done

# Every file must verify BEFORE enrollment - enrollment is hard to undo
echo "Verifying signatures before enrollment..."
if ! sudo sbctl verify; then
  echo "error: sbctl verify reports unsigned or badly signed files." >&2
  echo "Fix these first (sudo sbctl sign -s <file>). Not enrolling." >&2
  exit 1
fi

echo ""
echo "All boot files are signed and verified."
echo ""
echo "Before enrolling keys, be ready for what can go wrong:"
echo "  - After enrollment, any file not signed with these keys will not boot."
echo "  - To recover: enter BIOS and disable Secure Boot (or boot a USB stick),"
echo "    then run 'sudo sbctl unenroll' or re-sign the missing files."
echo "  - Keep a bootable USB / BIOS access available for the first reboot."
echo ""

# Only enroll when a human explicitly says so, and only when we have a terminal
enroll=""
if [ -t 0 ] && [ -e /dev/tty ]; then
  read -r -p "Enroll Secure Boot keys now? [y/N] " enroll </dev/tty || enroll=""
fi

case "$enroll" in
y | Y | yes | YES)
  sudo sbctl enroll-keys --microsoft
  ;;
*)
  echo "Enrollment skipped. Nothing has been enrolled."
  echo "When you are ready, run: sudo sbctl enroll-keys --microsoft"
  exit 0
  ;;
esac

sudo sbctl status

if sudo sbctl verify; then
  echo ""
  echo "Success: every file is signed and verified."
  echo "Reboot and confirm the machine boots with Secure Boot enabled."
else
  echo "error: verification failed after signing. Do not reboot yet." >&2
  exit 1
fi
