#!/usr/bin/bash

PreviousWD=$(pwd)
skip_watermark=false
if [ "$1" = "--skip-watermark" ]; then
    skip_watermark=true
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

    --------------- Single Download script (Beta) --------------- 
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

#Install prerequisites
sudo pacman -Syu git zsh curl wget whiptail --noconfirm --needed

if command -v pacman >/dev/null; then
    echo "pacman detected. Installing prerequisites"
    sudo pacman -Syu git zsh curl wget whiptail --noconfirm --needed
fi

if command -v apt >/dev/null; then
    echo "apt detected. Installing prerequisites"
    sudo apt update
    sudo apt full-upgrade -y
    sudo apt install git zsh curl wget whiptail -y
fi

# Ensure whiptail is installed
if ! command -v whiptail >/dev/null; then
    echo "whiptail is not installed. Installing it now..."

     if command -v pacman >/dev/null; then
        echo "pacman detected. Installing prerequisites"
        sudo pacman -S whiptail --noconfirm || { echo "Failed to install whiptail. Exiting."; exit 1; }
        # Reload zsh if it exists
            if command -v zsh -h >/dev/null; then
                source ~/.zshrc
            fi
        # Reload Bash
        source ~/.bashrc
     fi
     
     if command -v apt >/dev/null; then
        echo "apt detected. Installing prerequisites"
        sudo apt install whiptail -y || { echo "Failed to install whiptail. Exiting."; exit 1; }
        # Reload zsh if it exists
            if command -v zsh -h >/dev/null; then
                source ~/.zshrc
            fi
        # Reload Bash
        source ~/.bashrc
     fi
     
fi

# Options for the whiptail menu
OPTIONS=(
    1 "Run zsh setup script" ON
    2 "Run LazyVim setup script" OFF
    3 "Install Docker" OFF
    4 "Install Pacman Packages" ON
    5 "Install Yay and AUR Packages" ON
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
    clean_selection=$(echo $selection | tr -d '"')
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
            echo "Running LazyVim setup script..."
            # Runs local script unless it does not exist or fails
            if [[ -f "LazyVim.sh" ]];then
                echo "Found local script, running..."
                bash LazyVim.sh
            else
                curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/LazyVim.sh | bash
            fi
            ;;
        "3")
            echo "Installing Docker..."
            if ! command -v docker >/dev/null; then
                echo "docker is NOT installed. Installing..."
                curl -fsSL https://get.docker.com | sh
                sudo usermod -aG docker $USER
            else
                sudo usermod -aG docker $USER
                echo "Docker is already installed."
                echo "+ sleep 10" && sleep 10
            fi
            ;;
        "4")
            echo "Installing Pacman Packages..."
            # Check if pacman binary is installed
            if command -v pacman </dev/null; then
                echo "Cannot proceed: pacman binary not found"
                exit 1 # exit with an error
            fi
            # Install pacman packages
            # Runs local script unless it does not exit or fails
            if [[ -f "./configs/PackagesPacman.txt" ]]; then
                echo "Found local config"
                cat ./configs/PackagesPacman.txt | sudo pacman -S - --needed --noconfirm
            elif ! curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/PackagesPacman.txt | sudo pacman -S - --needed --noconfirm; then
                echo "--------------------------------------------------------------------"
                echo "Failed to install Pacman packages. You can try running it manually:"
                echo "curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/PackagesPacman.txt | sudo pacman -S - --needed --noconfirm"
                echo "--------------------------------------------------------------------"
                echo "+ sleep 10" && sleep 10
            fi
            ;;
        "5")
            echo "Installing Yay and Yay Packages..."
            # Check for pacman before installing yay
            if command -v pacman </dev/null; then
                echo "Cannot proceed: Not a arch based system"
                exit 1 # Exit with an error
            fi
            # Install yay prerequisites
            if ! sudo pacman -S --needed --noconfirm efibootmgr sbsigntools mokutil sbctl golang fakeroot debugedit make gcc; then
                echo "--------------------------------------------------------------------"
                echo "Failed to install prerequisite packages for Yay. You can try running it manually:"
                echo "sudo pacman -S --needed --noconfirm efibootmgr sbsigntools mokutil sbctl golang fakeroot debugedit make gcc"
                echo "--------------------------------------------------------------------"
                exit 1 # exit with an error
            fi
            # Check if yay binary exists
            if ! command -v yay >/dev/null; then
                echo "yay is NOT installed. Running installation commands..."
                if ! git clone https://aur.archlinux.org/yay.git /tmp/yay_install; then
                    echo "--------------------------------------------------------------------"
                    echo "Failed to clone yay repository. You can try running it manually:"
                    echo "git clone https://aur.archlinux.org/yay.git /tmp/yay_install"
                    echo "--------------------------------------------------------------------"
                    exit 1 # exit with an error
                elif ! (cd /tmp/yay_install && makepkg -si --noconfirm); then
                    echo "--------------------------------------------------------------------"
                    echo "Failed to build and install yay. You can try running it manually:"
                    echo "cd /tmp/yay_install && makepkg -si --noconfirm"
                    echo "--------------------------------------------------------------------"
                    exit 1 # exit with an error
                fi
                cd $PreviousWD
                rm -rf /tmp/yay_install
            else
                echo "Yay is already installed."
            fi
            # Install yay packages
            # Runs local script unless it does no exist or fails
            if [[ -f "./config/PackagesYay.txt" ]]; then
                echo "Found local config"
                cat ./config/PackagesYay.txt | yay -S --needed --save --answerclean None --answerdiff None - --noconfirm
            elif ! curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/PackagesYay.txt | yay -S --needed --save --answerclean None --answerdiff None - --noconfirm; then
                echo "--------------------------------------------------------------------"
                echo "Failed to install Yay packages. You can try running it manually:"
                echo "curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/PackagesYay.txt | yay -S --needed --save --answerclean None --answerdiff None - --noconfirm"
                echo "--------------------------------------------------------------------"
                echo "+ sleep 10" && sleep 10
            fi
            ;;
        *)
            echo "Invalid option selected: $selection"
            ;; 
    esac
done

echo "Installation process complete."
