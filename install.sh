#!/usr/bin/bash

PreviousWD=$(pwd)
skip_watermark=false
if [ "$1" = "--skip-watermark" ]; then
  skip_watermark=true
fi

# Detect fish shell and ask user to switch to bash (bash-only syntax)
if [ -n "${FISH_VERSION:-}" ] || case "$SHELL" in *fish*) ;; *) false ;; esac then
  echo "Warning: fish shell detected."
  echo "This script is written for bash and may have syntax issues under fish."
  echo "Please switch to bash first and re-run it, e.g.: bash $0"
  read -r -p "Press Enter to continue anyway, or Ctrl+C to cancel..." </dev/tty || true
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

# Install shelly as a dependency if not present (Arch-based)
if command -v pacman >/dev/null; then
  # Install build prerequisites for shelly
  if ! sudo pacman -S --needed --noconfirm base-devel git; then
    echo "--------------------------------------------------------------------"
    echo "Failed to install prerequisite packages for Shelly. You can try running it manually:"
    echo "sudo pacman -S --needed --noconfirm base-devel git"
    echo "--------------------------------------------------------------------"
    exit 1 # exit with an error
  fi
  # Check if shelly binary exists
  if ! command -v shelly >/dev/null; then
    echo "shelly is NOT installed. Running installation commands..."
    if ! git clone https://aur.archlinux.org/shelly.git /tmp/shelly_install; then
      echo "--------------------------------------------------------------------"
      echo "Failed to clone shelly repository. You can try running it manually:"
      echo "git clone https://aur.archlinux.org/shelly.git /tmp/shelly_install"
      echo "--------------------------------------------------------------------"
      exit 1 # exit with an error
    elif ! (cd /tmp/shelly_install && makepkg -si --noconfirm); then
      echo "--------------------------------------------------------------------"
      echo "Failed to build and install shelly. You can try running it manually:"
      echo "cd /tmp/shelly_install && makepkg -si --noconfirm"
      echo "--------------------------------------------------------------------"
      exit 1 # exit with an error
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
  shelly install standard git zsh curl wget libnewt rsync whiptail --upgrade --no-confirm
fi

if command -v apt >/dev/null; then
  echo "apt detected. Installing prerequisites"
  sudo apt update
  sudo apt full-upgrade -y
  sudo apt install git zsh curl wget whiptail rsync -y
fi

# Ensure whiptail is installed
if ! command -v whiptail >/dev/null; then
  echo "whiptail is not installed. Installing it now..."

  if command -v shelly >/dev/null; then
    echo "shelly detected. Installing whiptail"
    shelly install standard whiptail --no-confirm || {
      echo "Failed to install whiptail. Exiting."
      exit 1
    }
  fi

  if command -v apt >/dev/null; then
    echo "apt detected. Installing whiptail"
    sudo apt install whiptail -y || {
      echo "Failed to install whiptail. Exiting."
      exit 1
    }
  fi

fi

# Options for the whiptail menu
OPTIONS=(
  1 "Run zsh setup script" OFF
  2 "Run fish setup script" ON
  3 "Run LazyVim setup script" OFF
  4 "Install Docker" OFF
  5 "Install Standard Packages (Shelly)" ON
  6 "Install AUR Packages (Shelly)" ON
  7 "Install affinity with GUI" OFF
  8 "Run bat setup script" ON
)

CHOICE=$(whiptail --title "Installation Options" --checklist \
  "Choose components to install:" 20 78 10 \
  "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

exitstatus=$?
if [ $exitstatus = 0 ]; then
  echo "User selected: $CHOICE"
else
  echo "User cancelled installation."
  exit 1
fi

# Fail on any command.
set -eu pipefail

# Process selected options
for selection in $CHOICE; do
  clean_selection=$(echo "$selection" | tr -d '"')
  case $clean_selection in
  "1")
    echo "Running zsh setup script..."
    # Runs local script unless it does not exist or fails
    if [[ -f "zsh.sh" ]]; then
      echo "Found local script, running..."
      bash zsh.sh --skip-watermark
    else
      bash "$(curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/zsh.sh)" --skip-watermark
    fi
    ;;
  "2")
    echo "Running fish setup script..."
    # Runs local script unless it does not exist or fails
    if [[ -f "fish.sh" ]]; then
      echo "Found local script, running..."
      bash fish.sh --skip-watermark
    else
      bash "$(curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/fish.sh)" --skip-watermark
    fi
    ;;
  "3")
    echo "Running LazyVim setup script..."
    # Runs local script unless it does not exist or fails
    if [[ -f "LazyVim.sh" ]]; then
      echo "Found local script, running..."
      bash LazyVim.sh
    else
      curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/LazyVim.sh | bash
    fi
    ;;
  "4")
    echo "Installing Docker..."
    if ! command -v docker >/dev/null; then
      echo "docker is NOT installed. Installing..."
      curl -fsSL https://get.docker.com | sh
      sudo usermod -aG docker "$USER"
    else
      sudo usermod -aG docker "$USER"
      echo "Docker is already installed."
      echo "+ sleep 10" && sleep 10
    fi
    ;;
  "5")
    echo "Installing Standard Packages via Shelly backup..."
    # Check if shelly binary is installed
    if ! command -v shelly >/dev/null; then
      echo "Cannot proceed: shelly binary not found"
      exit 1 # exit with an error
    fi
    # Install standard packages from shelly backup
    # Runs local script unless it does not exist or fails
    if [[ -f "./configs/shelly-standard.toml" ]]; then
      echo "Found local backup"
      shelly backup --import --name shelly-standard --directory ./configs --no-confirm
    elif ! curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-standard.toml -o /tmp/shelly-standard.toml; then
      echo "--------------------------------------------------------------------"
      echo "Failed to download shelly backup. You can try running it manually:"
      echo "curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-standard.toml -o /tmp/shelly-standard.toml"
      echo "--------------------------------------------------------------------"
      echo "+ sleep 10" && sleep 10
    elif ! shelly backup --import --name shelly-standard --directory /tmp --no-confirm; then
      echo "--------------------------------------------------------------------"
      echo "Failed to install Standard packages. You can try running it manually:"
      echo "shelly backup --import --name shelly-standard --directory /tmp --no-confirm"
      echo "--------------------------------------------------------------------"
      echo "+ sleep 10" && sleep 10
    fi
    ;;
  "6")
    echo "Installing AUR Packages via Shelly backup..."
    # Check for shelly before installing AUR packages
    if ! command -v shelly >/dev/null; then
      echo "Cannot proceed: shelly binary not found"
      exit 1 # Exit with an error
    fi
    # Install AUR packages from shelly backup
    # Runs local script unless it does not exist or fails
    if [[ -f "./configs/shelly-aur.toml" ]]; then
      echo "Found local backup"
      shelly backup --import --name shelly-aur --directory ./configs --no-confirm
    elif ! curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-aur.toml -o /tmp/shelly-aur.toml; then
      echo "--------------------------------------------------------------------"
      echo "Failed to download shelly backup. You can try running it manually:"
      echo "curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-aur.toml -o /tmp/shelly-aur.toml"
      echo "--------------------------------------------------------------------"
      echo "+ sleep 10" && sleep 10
    elif ! shelly backup --import --name shelly-aur --directory /tmp --no-confirm; then
      echo "--------------------------------------------------------------------"
      echo "Failed to install AUR packages. You can try running it manually:"
      echo "shelly backup --import --name shelly-aur --directory /tmp --no-confirm"
      echo "--------------------------------------------------------------------"
      echo "+ sleep 10" && sleep 10
    fi
    ;;
  "7")
    echo "Installing GUI dependencies"
    if command -v shelly >/dev/null; then
      echo "shelly found"
      shelly install standard python-pyqt6 --no-confirm
    fi
    if command -v dnf >/dev/null; then
      echo "dnf found"
      sudo dnf install python3-pyqt6
    fi
    if command -v apt >/dev/null; then
      echo "apt found"
      sudo apt install python3-pyqt6 -y
    fi
    echo "Install affinity with ryzendew's gui installer"
    echo "You must manually select to install in the GUI"
    echo "Github repo: https://github.com/ryzendew/Linux-Affinity-Installer"
    echo "+ 10 sleep"
    sleep 10
    curl -sSL https://raw.githubusercontent.com/ryzendew/AffinityOnLinux/refs/heads/main/AffinityScripts/AffinityLinuxInstaller.py | python3
    ;;
  "8")
    echo "Running bat setup script..."
    # Runs local script unless it does not exist or fails
    if [[ -f "bat.sh" ]]; then
      echo "Found local script, running..."
      bash bat.sh --skip-watermark
    else
      bash "$(curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/bat.sh)" --skip-watermark
    fi
    ;;

  *)
    echo "Invalid option selected: $selection"
    ;;
  esac
done

echo "Installation process complete."
