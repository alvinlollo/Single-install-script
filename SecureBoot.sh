#!/usr/bin/bash

# Detect fish shell and ask user to switch to bash (bash-only syntax)
if [ -n "${FISH_VERSION:-}" ] || case "$SHELL" in *fish*) ;; *) false ;; esac; then
  echo "Warning: fish shell detected."
  echo "This script is written for bash and may have syntax issues under fish."
  echo "Please switch to bash first and re-run it, e.g.: bash $0"
  read -r -p "Press Enter to continue anyway, or Ctrl+C to cancel..." </dev/tty || true
fi

# Install Prerequisites
sudo pacman -S --needed -noconfirm efibootmgr sbsigntools mokutil sbctl grub

sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft
sudo sbctl verify
# use sudo sbctl sign -s for every unsigned item
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
sudo sbctl sign -s /boot/grub/x84_64-efi/core.efi
sudo sbctl sign -s /boot/grub/x86_64-efi/grub.efi
sudo sbctl sign -s /boot/vmlinuz-linux

sudo sbctl status
sudo sbctl verify
echo "Use sudo sbctl sign -s for every unsigned item"
