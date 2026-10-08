#!/usr/bin/bash

PreviousWD=$(pwd)
skip_watermark=false
if [ "$1" = "--skip-watermark" ]; then
  skip_watermark=true
fi

# Detect fish shell and warn user to run with bash instead (bash-only syntax)
if [ -n "${FISH_VERSION:-}" ] || case "$SHELL" in *fish*) ;; *) false ;; esac then
  if command -v gum >/dev/null; then
    if ! gum confirm "$(printf 'Your default shell appears to be fish.\n\nThis script must be run with bash. It uses bash-only syntax and will fail under fish.\n\nRun it with:\n  bash installbeta.sh\n\nContinue anyway?')"; then
      echo "Aborted. Please run this script with bash, not fish. e.g.: bash installbeta.sh"
      exit 1
    fi
  else
    echo "Warning: fish shell detected."
    echo "This script must be run with bash, not fish (bash-only syntax)."
    echo "Please run it with bash, e.g.: bash installbeta.sh"
    read -r -p "Press Enter to continue anyway, or Ctrl+C to cancel..." </dev/tty || true
  fi
fi

if [ "$skip_watermark" = false ]; then
  clear
  echo '
     ____                _       _       _       _ _
    | __ ) _   _    __ _| |_   _(_)_ __ | | ___ | | | ___
    |  _ \| | | |  / _  | \ \ / / |  _ \| |/ _ \| | |/ _ \
    | |_) | |_| | | (_| | |\ V /| | | | | | (_) | | | (_) |
    |____/ \__  |  \__ _|_| \_/ |_|_| |_|_|\___/|_|_|\___/ 
            |___/ 

    --------------- Single Download script --------------- 
BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE UNDER THE GPL-2.0 LICENCE, 
THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. 
See the LICENCE for more detail
'
fi

# Function to display error message
function error_handler() {
  set +x
  echo -e "An error occurred. Please check the output above for details."
}

# Trap errors
trap error_handler ERR

# --- Failure handling & full console log ------------------------------------
# Everything from here on is teed to a log file in /tmp, and Arch-only step
# failures are recorded instead of aborting the rest of the installation.
TTY_OK=false
[ -t 1 ] && TTY_OK=true

LOG="/tmp/installbeta-$(date +%Y%m%d-%H%M%S).log"
REPORT="/tmp/installbeta-failures-$(date +%Y%m%d-%H%M%S).txt"
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

# Install shelly as a dependency if not present (Arch-based)
if command -v pacman >/dev/null; then
  # Install build prerequisites for shelly
  if ! sudo pacman -S --needed --noconfirm base-devel git; then
    echo "--------------------------------------------------------------------"
    echo "Failed to install prerequisite packages for Shelly. You can try running it manually:"
    echo "sudo pacman -S --needed --noconfirm base-devel git"
    echo "--------------------------------------------------------------------"
    record_failure "Shelly bootstrap (Arch-only)" "failed to install base-devel/git prerequisites"
  fi
  # Check if shelly binary exists
  if ! command -v shelly >/dev/null; then
    echo "shelly is NOT installed. Running installation commands..."
    if ! git clone https://aur.archlinux.org/shelly.git /tmp/shelly_install; then
      echo "--------------------------------------------------------------------"
      echo "Failed to clone shelly repository. You can try running it manually:"
      echo "git clone https://aur.archlinux.org/shelly.git /tmp/shelly_install"
      echo "--------------------------------------------------------------------"
      record_failure "Shelly bootstrap (Arch-only)" "failed to clone the shelly AUR repository"
    elif ! (cd /tmp/shelly_install && makepkg -si --noconfirm); then
      echo "--------------------------------------------------------------------"
      echo "Failed to build and install shelly. You can try running it manually:"
      echo "cd /tmp/shelly_install && makepkg -si --noconfirm"
      echo "--------------------------------------------------------------------"
      record_failure "Shelly bootstrap (Arch-only)" "failed to build shelly with makepkg"
    fi
    cd "$PreviousWD"
    rm -rf /tmp/shelly_install
  else
    echo "Shelly is already installed."
  fi
fi

# Install prerequisites
if command -v shelly >/dev/null; then
  echo "Shelly detected. Installing prerequisites"
  shelly install standard git zsh curl wget libnewt rsync gum --upgrade --no-confirm ||
    record_failure "Prerequisites (shelly)" "installing base packages via shelly failed"
fi

if command -v apt >/dev/null; then
  echo "apt detected. Installing prerequisites"
  sudo apt update || record_failure "Prerequisites (apt)" "apt update failed"
  sudo apt full-upgrade -y || record_failure "Prerequisites (apt)" "apt full-upgrade failed"
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

CHOICE=$(gum_tty choose --no-limit --height 14 \
  --header "Tab = select, Enter = confirm:" \
  --selected "Run fish setup script,Install Standard Packages (Shelly),Install AUR Packages (Shelly),Run bat setup script" \
  "${OPTIONS[@]}") || {
  echo "User cancelled installation."
  exit 1
}

echo "User selected:"
echo "$CHOICE"

# Fail on any command.
set -euo pipefail

# Process selected options in menu order
while IFS= read -r selection; do
  # Skip options the user did not select
  grep -qxF "$selection" <<<"$CHOICE" || continue
  case "$selection" in
  "Run zsh setup script")
    echo "Running zsh setup script..."
    # Runs local script unless it does not exist or fails
    if [[ -f "zsh.sh" ]]; then
      echo "Found local script, running..."
      bash zsh.sh --skip-watermark ||
        record_failure "Run zsh setup script" "zsh.sh exited with status $?"
    else
      curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/zsh.sh | bash -s -- --skip-watermark ||
        record_failure "Run zsh setup script" "downloaded zsh.sh exited with status $?"
    fi
    ;;
  "Run fish setup script")
    echo "Running fish setup script..."
    # Runs local script unless it does not exist or fails
    if [[ -f "fish.sh" ]]; then
      echo "Found local script, running..."
      bash fish.sh --skip-watermark ||
        record_failure "Run fish setup script" "fish.sh exited with status $?"
    else
      curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/fish.sh | bash -s -- --skip-watermark ||
        record_failure "Run fish setup script" "downloaded fish.sh exited with status $?"
    fi
    ;;
  "Run LazyVim setup script")
    echo "Running LazyVim setup script..."
    # Runs local script unless it does not exist or fails
    if [[ -f "LazyVim.sh" ]]; then
      echo "Found local script, running..."
      bash LazyVim.sh ||
        record_failure "Run LazyVim setup script" "LazyVim.sh exited with status $?"
    else
      curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/LazyVim.sh | bash ||
        record_failure "Run LazyVim setup script" "downloaded LazyVim.sh exited with status $?"
    fi
    ;;
  "Install Docker")
    echo "Installing Docker..."
    if ! command -v docker >/dev/null; then
      echo "docker is NOT installed. Installing..."
      curl -fsSL https://get.docker.com | sh ||
        record_failure "Install Docker" "docker installer script exited with status $?"
      sudo usermod -aG docker "$USER" ||
        record_failure "Install Docker" "adding $USER to the docker group failed"
    else
      sudo usermod -aG docker "$USER" ||
        record_failure "Install Docker" "adding $USER to the docker group failed"
      echo "Docker is already installed."
      echo "+ sleep 10" && sleep 10
    fi
    ;;
  "Install Standard Packages (Shelly)")
    echo "Installing Standard Packages via Shelly backup..."
    # Check if shelly binary is installed
    if ! command -v shelly >/dev/null; then
      echo "Cannot proceed: shelly binary not found (Arch-only)"
      record_failure "Install Standard Packages (Shelly)" "shelly binary not found (Arch-only)"
    # Install standard packages from shelly backup
    # Runs local script unless it does not exist or fails
    elif [[ -f "./configs/shelly-standard.toml" ]]; then
      echo "Found local backup"
      shelly backup --import --name shelly-standard --directory ./configs --no-confirm ||
        record_failure "Install Standard Packages (Shelly)" "shelly backup import exited with status $?"
    elif ! curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-standard.toml -o /tmp/shelly-standard.toml; then
      echo "--------------------------------------------------------------------"
      echo "Failed to download shelly backup. You can try running it manually:"
      echo "curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-standard.toml -o /tmp/shelly-standard.toml"
      echo "--------------------------------------------------------------------"
      record_failure "Install Standard Packages (Shelly)" "failed to download shelly-standard.toml"
      echo "+ sleep 10" && sleep 10
    elif ! shelly backup --import --name shelly-standard --directory /tmp --no-confirm; then
      echo "--------------------------------------------------------------------"
      echo "Failed to install Standard packages. You can try running it manually:"
      echo "shelly backup --import --name shelly-standard --directory /tmp --no-confirm"
      echo "--------------------------------------------------------------------"
      record_failure "Install Standard Packages (Shelly)" "shelly backup import failed"
      echo "+ sleep 10" && sleep 10
    fi
    ;;
  "Install AUR Packages (Shelly)")
    echo "Installing AUR Packages via Shelly backup..."
    # Check for shelly before installing AUR packages
    if ! command -v shelly >/dev/null; then
      echo "Cannot proceed: shelly binary not found (Arch-only)"
      record_failure "Install AUR Packages (Shelly)" "shelly binary not found (Arch-only)"
    # Install AUR packages from shelly backup
    # Runs local script unless it does not exist or fails
    elif [[ -f "./configs/shelly-aur.toml" ]]; then
      echo "Found local backup"
      shelly backup --import --name shelly-aur --directory ./configs --no-confirm ||
        record_failure "Install AUR Packages (Shelly)" "shelly backup import exited with status $?"
    elif ! curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-aur.toml -o /tmp/shelly-aur.toml; then
      echo "--------------------------------------------------------------------"
      echo "Failed to download shelly backup. You can try running it manually:"
      echo "curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-aur.toml -o /tmp/shelly-aur.toml"
      echo "--------------------------------------------------------------------"
      record_failure "Install AUR Packages (Shelly)" "failed to download shelly-aur.toml"
      echo "+ sleep 10" && sleep 10
    elif ! shelly backup --import --name shelly-aur --directory /tmp --no-confirm; then
      echo "--------------------------------------------------------------------"
      echo "Failed to install AUR packages. You can try running it manually:"
      echo "shelly backup --import --name shelly-aur --directory /tmp --no-confirm"
      echo "--------------------------------------------------------------------"
      record_failure "Install AUR Packages (Shelly)" "shelly backup import failed"
      echo "+ sleep 10" && sleep 10
    fi
    ;;
  "Install affinity with GUI")
    echo "Installing GUI dependencies"
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
    echo "+ 10 sleep"
    sleep 10
    curl -sSL https://raw.githubusercontent.com/ryzendew/AffinityOnLinux/refs/heads/main/AffinityScripts/AffinityLinuxInstaller.py | python3 ||
      record_failure "Install affinity with GUI" "affinity installer exited with status $?"
    ;;
  "Run bat setup script")
    echo "Running bat setup script..."
    # Runs local script unless it does not exist or fails
    if [[ -f "bat.sh" ]]; then
      echo "Found local script, running..."
      bash bat.sh --skip-watermark ||
        record_failure "Run bat setup script" "bat.sh exited with status $?"
    else
      curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/bat.sh | bash -s -- --skip-watermark ||
        record_failure "Run bat setup script" "downloaded bat.sh exited with status $?"
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
    gum_tty pager < "$REPORT" || true
  fi
else
  echo "All steps completed with no failures."
fi

exit 0
