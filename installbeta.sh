#!/usr/bin/bash

# Strict mode from the very start: every tolerated failure in this script is
# an explicit guard (if ! / || record_failure), so preamble steps are checked
# too. Anything unguarded aborts the run via errexit.
set -euo pipefail

skip_watermark=false
if [ "${1:-}" = "--skip-watermark" ]; then
  skip_watermark=true
fi

if [ "$skip_watermark" = false ]; then
  clear 2>/dev/null || true
  echo '
     ____                _       _       _       _ _
    | __ ) _   _    __ _| |_   _(_)_ __ | | ___ | | | ___
    |  _ \| | | |  / _  | \ \ / / |  _ \| |/ _ \| | |/ _ \
    | |_) | |_| | | (_| | |\ V /| | | | | | (_) | | | (_) |
    |____/ \__  |  \__ _|_| \_/ |_|_| |_|_|\___/|_|_|\___/ 
            |___/ 

    --------------- Single Download script --------------- 
BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE UNDER THE GPL-2.0 LICENSE, 
THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. 
See the LICENSE for more detail
'
fi

# --- Failure handling & full console log ------------------------------------
# Everything from here on is teed to a log file in /tmp, and Arch-only step
# failures are recorded instead of aborting the rest of the installation.
TTY_OK=false
if [ -t 1 ]; then
  TTY_OK=true
fi

# One timestamp for both files, mktemp so the names are not predictable
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$(mktemp "/tmp/installbeta-$STAMP-XXXXXX.log")"
REPORT="$(mktemp "/tmp/installbeta-failures-$STAMP-XXXXXX.txt")"
FAILED=()

exec > >(tee -a "$LOG") 2>&1

# gum draws its TUI on stderr - keep that on the real terminal, not the log pipe
gum_tty() {
  if [ "$TTY_OK" = true ]; then
    gum "$@" 2>/dev/tty
  else
    gum "$@"
  fi
}

# Record a failed step: remember it, print it now, keep installing
record_failure() {
  FAILED+=("$1 — $2")
  echo "!! FAILED: $1 — $2  (continuing with the rest of the installation)"
  echo "$(date '+%F %T')  $1 — $2" >>"$REPORT"
}

# Private temp workspace for downloads and clones. Predictable names in /tmp
# are a symlink attack vector on multi-user systems; the trap cleans up too.
WORK_DIR="$(mktemp -d)"

# Also stops the sudo keep-alive loop below when the script exits (any path:
# normal end, menu cancel, errexit, signal). SUDO_LOOP_PID is unset if the
# script bails out before the loop starts, hence the default value.
cleanup() {
  if [ -n "${SUDO_LOOP_PID:-}" ]; then
    kill "$SUDO_LOOP_PID" 2>/dev/null || true
  fi
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# Resolve where this script lives so local script/config fallbacks do not
# depend on the caller's current directory. Empty when piped (curl | bash).
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  SCRIPT_DIR=""
fi

sudo -v # Ask for sudo upfront so the user is prompted only once

# Sudo keep-alive loop
sudo_keep_alive() {
  while true; do
    sleep 250
    sudo -n true 2>/dev/null || true
    # $$ is the main script's PID even in this background subshell: exit as
    # soon as the installer is gone, as a backstop for the EXIT trap.
    kill -0 "$$" 2>/dev/null || exit
  done
}
sudo_keep_alive &
SUDO_LOOP_PID=$!
echo "Keeping sudo alive on PID $SUDO_LOOP_PID - refreshing every 250s"

# Install prerequisites
if command -v shelly >/dev/null; then
  echo "Shelly detected. Installing prerequisites"
  shelly install standard base-devel git zsh curl wget libnewt rsync gum --upgrade --no-confirm ||
    record_failure "Prerequisites (shelly)" "installing base packages via shelly failed"
fi

if command -v apt >/dev/null; then
  echo "apt detected. Installing prerequisites"
  sudo apt update || record_failure "Prerequisites (apt)" "apt update failed"
  sudo apt full-upgrade -y || record_failure "Prerequisites (apt)" "apt full-upgrade failed"
  sudo -v
  sudo apt install git zsh curl wget rsync gum -y ||
    record_failure "Prerequisites (apt)" "apt install of base packages failed"
fi

# Ensure gum is installed
if ! command -v gum >/dev/null; then
  echo "gum is not installed. Installing it now..."

  if command -v shelly >/dev/null; then
    echo "shelly detected. Installing gum"
    shelly install standard gum --no-confirm || {
      echo "Failed to install gum. Exiting."
      exit 1
    }
  fi

  if command -v apt >/dev/null; then
    echo "apt detected. Installing gum"
    sudo apt install gum -y || {
      echo "Failed to install gum. Exiting."
      exit 1
    }
  fi
fi

# Install shelly as a dependency if not present (Arch-based)
if command -v pacman >/dev/null; then
  # Install build prerequisites for shelly
  if ! gum spin --show-error -s dot --title "Install base-devel and git" -- sudo pacman -S --needed --noconfirm base-devel git; then
    echo "--------------------------------------------------------------------"
    echo "Failed to install prerequisite packages for Shelly. You can try running it manually:"
    echo "sudo pacman -S --needed --noconfirm base-devel git"
    echo "--------------------------------------------------------------------"
    record_failure "Shelly bootstrap (Arch-only)" "failed to install base-devel/git prerequisites"
  fi
  # Check if shelly binary exists
  if ! command -v shelly >/dev/null; then
    echo "shelly is NOT installed. Running installation commands..."
    if ! gum spin --show-error -s dot --title "Clone Shelly from AUR" -- git clone https://aur.archlinux.org/shelly.git "$WORK_DIR/shelly"; then
      echo "--------------------------------------------------------------------"
      echo "Failed to clone shelly repository. You can try running it manually:"
      echo "git clone https://aur.archlinux.org/shelly.git \"$WORK_DIR/shelly\""
      echo "--------------------------------------------------------------------"
      record_failure "Shelly bootstrap (Arch-only)" "failed to clone the shelly AUR repository"
    elif ! (cd "$WORK_DIR/shelly" && gum spin --show-error -s dot --title "Install Shelly" makepkg -si --noconfirm); then
      echo "--------------------------------------------------------------------"
      echo "Failed to build and install shelly. You can try running it manually:"
      echo "cd \"$WORK_DIR/shelly\" && makepkg -si --noconfirm"
      echo "--------------------------------------------------------------------"
      record_failure "Shelly bootstrap (Arch-only)" "failed to build shelly with makepkg"
    fi
  else
    echo "Shelly is already installed."
  fi
fi

# gum drives every interactive dialog in this script and there is no fallback
# menu, so a system that ended up without it must abort here.
if ! command -v gum >/dev/null; then
  echo "gum is required but could not be installed on this system (no shelly/apt found)." >&2
  echo "Install it manually: https://github.com/charmbracelet/gum" >&2
  exit 1
fi

# Detect fish shell and warn user to run with bash instead (bash-only syntax).
# Placed after the gum bootstrap above so the dialog can always use gum confirm
# instead of falling back to a plain text prompt.
if [ -n "${FISH_VERSION:-}" ] || case "${SHELL:-}" in *fish*) ;; *) false ;; esac then
  if ! gum_tty confirm "$(printf 'Your default shell appears to be fish.\n\nThis script must be run with bash. It uses bash-only syntax and will fail under fish.\n\nRun it with:\n  bash installbeta.sh\n\nContinue anyway?')"; then
    echo "Aborted. Please run this script with bash, not fish. e.g.: bash installbeta.sh"
    exit 1
  fi
fi

# Options for the gum menu
OPTIONS=(
  "Run zsh setup script"
  "Run fish setup script"
  "Run LazyVim setup script"
  "Install Docker"
  "Install Standard Packages (Shelly)"
  "Install AUR Packages (Shelly)"
  "Install affinity with GUI"
  "Run bat setup script"
)

# Present the menu with gum (gum is guaranteed by the bootstrap above)
if ! CHOICE=$(gum_tty choose --no-limit --height 14 \
  --header "Tab = select, Enter = confirm:" \
  --selected "Run fish setup script,Install Standard Packages (Shelly),Install AUR Packages (Shelly),Run bat setup script" \
  "${OPTIONS[@]}"); then
  echo "No options selected (menu cancelled). Nothing was installed."
  exit 1
fi

# gum exits 0 with empty output when nothing is selected - treat that as a
# cancel too, otherwise the run below would silently install nothing.
if [ -z "$CHOICE" ]; then
  echo "No options selected. Nothing was installed."
  exit 1
fi

echo "User selected:"
echo "$CHOICE"

# Process selected options in menu order
while IFS= read -r selection; do
  # Skip options the user did not select
  grep -qxF "$selection" <<<"$CHOICE" || continue
  case "$selection" in
  "Run zsh setup script")
    echo "Running zsh setup script..."
    sudo -v
    # Runs local script unless it does not exist (SCRIPT_DIR, not CWD)
    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/zsh.sh" ]; then
      echo "Found local script, running..."
      gum spin --show-error -s dot --title "Installing zsh with local script" -- bash "$SCRIPT_DIR/zsh.sh" --skip-watermark || {
        rc=$?
        record_failure "Run zsh setup script" "zsh.sh exited with status $rc"
      }
    else
      curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/zsh.sh | gum spin --show-error -s dot --title "Installing zsh" -- bash -s -- --skip-watermark || {
        rc=$?
        record_failure "Run zsh setup script" "downloaded zsh.sh exited with status $rc"
      }
    fi
    ;;
  "Run fish setup script")
    echo "Running fish setup script..."
    sudo -v
    # Runs local script unless it does not exist (SCRIPT_DIR, not CWD)
    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/fish.sh" ]; then
      echo "Found local script, running..."
      gum spin --show-error -s dot --title "Installing fish with local script" -- bash "$SCRIPT_DIR/fish.sh" --skip-watermark || {
        rc=$?
        record_failure "Run fish setup script" "fish.sh exited with status $rc"
      }
    else
      gum spin --show-error -s dot --title "Installing fish shell" \
        bash -c "curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/fish.sh | bash -s -- --skip-watermark" || {
        rc=$?
        record_failure "Run fish setup script" "downloaded fish.sh exited with status $rc"
      }
    fi
    ;;
  "Run LazyVim setup script")
    echo "Running LazyVim setup script..."
    sudo -v
    # Runs local script unless it does not exist (SCRIPT_DIR, not CWD)
    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/LazyVim.sh" ]; then
      echo "Found local script, running..."
      bash "$SCRIPT_DIR/LazyVim.sh" || {
        rc=$?
        record_failure "Run LazyVim setup script" "LazyVim.sh exited with status $rc"
      }
    else
      curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/LazyVim.sh | bash || {
        rc=$?
        record_failure "Run LazyVim setup script" "downloaded LazyVim.sh exited with status $rc"
      }
    fi
    ;;
  "Install Docker")
    echo "Installing Docker..."
    sudo -v
    if ! command -v docker >/dev/null; then
      echo "docker is NOT installed. Installing..."
      if curl -fsSL https://get.docker.com -o "$WORK_DIR/get-docker.sh" &&
        sh "$WORK_DIR/get-docker.sh"; then
        sudo usermod -aG docker "$USER" ||
          record_failure "Install Docker" "adding $USER to the docker group failed"
      else
        rc=$?
        record_failure "Install Docker" "docker installer script exited with status $rc"
      fi
    else
      sudo usermod -aG docker "$USER" ||
        record_failure "Install Docker" "adding $USER to the docker group failed"
      echo "Docker is already installed."
    fi
    echo "NOTE: $USER has been added to the docker group."
    echo "Log out and back in (or reboot) for the group membership to take effect."
    ;;
  "Install Standard Packages (Shelly)")
    echo "Installing Standard Packages via Shelly backup..."
    # Check if shelly binary is installed
    if ! command -v shelly >/dev/null; then
      echo "Cannot proceed: shelly binary not found (Arch-only)"
      record_failure "Install Standard Packages (Shelly)" "shelly binary not found (Arch-only)"
      # Install standard packages from shelly backup
      # Runs local script unless it does not exist (SCRIPT_DIR, not CWD)
      sudo -v
    elif [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/configs/shelly-standard.toml" ]; then
      echo "Found local backup"
      shelly backup --import --name shelly-standard --directory "$SCRIPT_DIR/configs" --no-confirm || {
        rc=$?
        record_failure "Install Standard Packages (Shelly)" "shelly backup import exited with status $rc"
      }
    elif ! curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-standard.toml -o "$WORK_DIR/shelly-standard.toml"; then
      echo "--------------------------------------------------------------------"
      echo "Failed to download shelly backup. You can try running it manually:"
      echo "curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-standard.toml -o \"$WORK_DIR/shelly-standard.toml\""
      echo "--------------------------------------------------------------------"
      record_failure "Install Standard Packages (Shelly)" "failed to download shelly-standard.toml"
    elif ! shelly backup --import --name shelly-standard --directory "$WORK_DIR" --no-confirm; then
      echo "--------------------------------------------------------------------"
      echo "Failed to install Standard packages. You can try running it manually:"
      echo "shelly backup --import --name shelly-standard --directory \"$WORK_DIR\" --no-confirm"
      echo "--------------------------------------------------------------------"
      record_failure "Install Standard Packages (Shelly)" "shelly backup import failed"
    fi
    ;;
  "Install AUR Packages (Shelly)")
    echo "Installing AUR Packages via Shelly backup..."
    sudo -v
    # Check for shelly before installing AUR packages
    if ! command -v shelly >/dev/null; then
      echo "Cannot proceed: shelly binary not found (Arch-only)"
      record_failure "Install AUR Packages (Shelly)" "shelly binary not found (Arch-only)"
    # Install AUR packages from shelly backup
    # Runs local script unless it does not exist (SCRIPT_DIR, not CWD)
    elif [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/configs/shelly-aur.toml" ]; then
      echo "Found local backup"
      shelly backup --import --name shelly-aur --directory "$SCRIPT_DIR/configs" --no-confirm || {
        rc=$?
        record_failure "Install AUR Packages (Shelly)" "shelly backup import exited with status $rc"
      }
    elif ! curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-aur.toml -o "$WORK_DIR/shelly-aur.toml"; then
      echo "--------------------------------------------------------------------"
      echo "Failed to download shelly backup. You can try running it manually:"
      echo "curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-aur.toml -o \"$WORK_DIR/shelly-aur.toml\""
      echo "--------------------------------------------------------------------"
      record_failure "Install AUR Packages (Shelly)" "failed to download shelly-aur.toml"
    elif ! shelly backup --import --name shelly-aur --directory "$WORK_DIR" --no-confirm; then
      echo "--------------------------------------------------------------------"
      echo "Failed to install AUR packages. You can try running it manually:"
      echo "shelly backup --import --name shelly-aur --directory \"$WORK_DIR\" --no-confirm"
      echo "--------------------------------------------------------------------"
      record_failure "Install AUR Packages (Shelly)" "shelly backup import failed"
    fi
    ;;
  "Install affinity with GUI")
    echo "Installing GUI dependencies"
    sudo -v
    if command -v shelly >/dev/null; then
      echo "shelly found"
      shelly install standard python-pyqt6 --no-confirm ||
        record_failure "Install affinity with GUI" "installing python-pyqt6 via shelly failed"
    fi
    if command -v dnf >/dev/null; then
      echo "dnf found"
      sudo dnf install python3-pyqt6 ||
        record_failure "Install affinity with GUI" "installing python3-pyqt6 via dnf failed"
    fi
    if command -v apt >/dev/null; then
      echo "apt found"
      sudo apt install python3-pyqt6 -y ||
        record_failure "Install affinity with GUI" "installing python3-pyqt6 via apt failed"
    fi
    echo "Install affinity with ryzendew's gui installer"
    echo "You must manually select to install in the GUI"
    echo "Github repo: https://github.com/ryzendew/Linux-Affinity-Installer"
    echo "Starting the GUI installer in 10 seconds - read the notes above first."
    sleep 10
    { curl -fsSL https://raw.githubusercontent.com/ryzendew/AffinityOnLinux/refs/heads/main/AffinityScripts/AffinityLinuxInstaller.py \
      -o "$WORK_DIR/AffinityLinuxInstaller.py" &&
      python3 "$WORK_DIR/AffinityLinuxInstaller.py"; } || {
      rc=$?
      record_failure "Install affinity with GUI" "affinity installer exited with status $rc"
    }
    ;;
  "Run bat setup script")
    echo "Running bat setup script..."
    # Runs local script unless it does not exist (SCRIPT_DIR, not CWD)
    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/bat.sh" ]; then
      echo "Found local script, running..."
      bash "$SCRIPT_DIR/bat.sh" --skip-watermark || {
        rc=$?
        record_failure "Run bat setup script" "bat.sh exited with status $rc"
      }
    else
      curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/bat.sh | bash -s -- --skip-watermark || {
        rc=$?
        record_failure "Run bat setup script" "downloaded bat.sh exited with status $rc"
      }
    fi
    ;;
  *)
    echo "Invalid option selected: $selection"
    ;;
  esac
done < <(printf '%s\n' "${OPTIONS[@]}")

echo "Installation process complete."

# Show (and save) what failed - the run itself never aborts on a failed step
if [ "${#FAILED[@]}" -gt 0 ]; then
  {
    echo ""
    echo "================ FAILURE SUMMARY ================"
    echo "installbeta.sh finished at $(date '+%F %T') - ${#FAILED[@]} step(s) failed:"
    printf '  - %s\n' "${FAILED[@]}"
    echo ""
    echo "Full console log: $LOG"
    echo "Failure report:   $REPORT"
    echo "==================================================="
  } | tee -a "$REPORT"

  if [ "$TTY_OK" = true ] && command -v gum >/dev/null; then
    gum_tty pager <"$REPORT" || true
  fi

  # Non-zero so callers and CI can detect the failed run
  exit 1
fi

echo "================ INSTALL SUMMARY ================"
echo "installbeta.sh finished at $(date '+%F %T') - ${#FAILED[@]} step(s) failed:"
echo ""
echo "Full console log: /tmp/installbeta-$STAMP-XXXXXX.log"
echo "Failure report:   $REPORT"
echo "==================================================="

exit 0
