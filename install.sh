#!/usr/bin/bash

clear
echo '
     ____                _       _       _       _ _
    | __ ) _   _    __ _| |_   _(_)_ __ | | ___ | | | ___
    |  _ \| | | |  / _  | \ \ / / |  _ \| |/ _ \| | |/ _ \
    | |_) | |_| | | (_| | |\ V /| | | | | | (_) | | | (_) |
    |____/ \__  |  \__ _|_| \_/ |_|_| |_|_|\___/|_|_|\___/ 
            |___/ 

    --------------- Single Download script (BETA) --------------- 
'

# Function to display error message
function error_handler() {
  set +x
  echo -e "An error occurred. Please check the output above for details."
}

# Trap errors
trap error_handler ERR

#Install prerequisites
sudo pacman -Syu git zsh curl --noconfirm --needed

# Ensure whiptail is installed
if ! command -v whiptail >/dev/null; then
    echo "whiptail is not installed. Installing it now..."
    sudo pacman -S --noconfirm whiptail || { echo "Failed to install whiptail. Exiting."; exit 1; }
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
            curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/zsh.sh | bash
            ;;
        "2")
            echo "Running LazyVim setup script..."
            curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/LazyVim.sh | bash
            ;;
        "3")
            echo "Installing Docker..."
            if ! command -v docker >/dev/null; then
                echo "docker is NOT installed. Running installation commands..."
                curl -fsSL https://get.docker.com | sh
                sudo usermod -aG docker $USER
            else
                echo "Docker is already installed."
            fi
            ;;
        "4")
            echo "Installing Pacman Packages..."
            if ! curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/PackagesPacman.txt | sudo pacman -S - --needed --noconfirm; then
                echo "--------------------------------------------------------------------"
                echo "Failed to install Pacman packages. You can try running it manually:"
                echo "curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/PackagesPacman.txt | sudo pacman -S - --needed --noconfirm"
                echo "--------------------------------------------------------------------"
            fi
            ;;
        "5")
            echo "Installing Yay and Yay Packages..."
            if ! sudo pacman -S --needed --noconfirm efibootmgr sbsigntools mokutil sbctl; then # These were in the original script before yay install
                echo "--------------------------------------------------------------------"
                echo "Failed to install prerequisite packages for Yay. You can try running it manually:"
                echo "sudo pacman -S --needed --noconfirm efibootmgr sbsigntools mokutil sbctl"
                echo "--------------------------------------------------------------------"
            fi
            if ! command -v yay >/dev/null; then
                echo "yay is NOT installed. Running installation commands..."
                if ! git clone https://aur.archlinux.org/yay.git /tmp/yay_install; then
                    echo "--------------------------------------------------------------------"
                    echo "Failed to clone yay repository. You can try running it manually:"
                    echo "git clone https://aur.archlinux.org/yay.git /tmp/yay_install"
                    echo "--------------------------------------------------------------------"
                elif ! (cd /tmp/yay_install && makepkg -si --noconfirm); then
                    echo "--------------------------------------------------------------------"
                    echo "Failed to build and install yay. You can try running it manually:"
                    echo "cd /tmp/yay_install && makepkg -si --noconfirm"
                    echo "--------------------------------------------------------------------"
                fi
                rm -rf /tmp/yay_install
            else
                echo "Yay is already installed."
            fi
            # Assuming PackagesYay.txt for yay packages, as per common practice
            if ! curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/PackagesYay.txt | yay -S --needed --save --answerclean All --answerdiff All - --noconfirm; then
                echo "--------------------------------------------------------------------"
                echo "Failed to install Yay packages. You can try running it manually:"
                echo "curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/PackagesYay.txt | yay -S --needed --save --answerclean All --answerdiff All - --noconfirm"
                echo "--------------------------------------------------------------------"
            fi
            ;;
        *)
            echo "Invalid option selected: $selection"
            ;; 
    esac
done

echo "Installation process complete."
