#!/bin/bash

clear
echo -e "\e[0m\c"

# shellcheck disable=SC2016
echo '
     ____                _       _       _       _ _
    | __ ) _   _    __ _| |_   _(_)_ __ | | ___ | | | ___
    |  _ \| | | |  / _  | \ \ / / |  _ \| |/ _ \| | |/ _ \
    | |_) | |_| | | (_| | |\ V /| | | | | | (_) | | | (_) |
    |____/ \__  |  \__ _|_| \_/ |_|_| |_|_|\___/|_|_|\___/
            |___/

    --------------- Single Download script ---------------
'

# Install prequisites
echo "Install prequisites"
echo
sudo apt update
sudo apt install -y git zsh curl git build-essential whiptail
echo

# Update system
echo "Update system"
echo
sudo apt full-upgrade -y
echo

# Build whiptail command

whiptail_command=(
    whiptail --title "Select Options" --checklist "Choose options to install" 28 85 20
)

whiptail_command+=(
    "Homebrew" "Installs homebrew using the install script" "OFF"
    "Oh-My-Zsh" "Installs Oh-My-Zsh with plugins and configurations" "ON"
    "GEF" "Installs GEF (https://github.com/hugsy/gef/)" "OFF"
    "apt Packages" "Installs packages and utilities" "ON"
    "Casa Os" "Installs CasaOs using the install script" "OFF"
    "Docker" "Installs Docker with install script" "OFF"
)

# Function to get user selections
get_user_selection() {
    local selections
    selections=$(whiptail "${whiptail_command[@]}" --output-fd 3 3>&1 1>&2 2>&1)

    if [ $? -ne 0 ]; then
        echo "INFO No options selected. Exiting."
        exit 1
    fi

    echo "$selections"
}

# Function to execute commands based on user selection
execute_commands() {
    local options=("$@")  # Get options as an array

    for option in "${options[@]}"; do
        case "$option" in
            "Homebrew")
                echo "INFO Executing commands for Homebrew"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                brew update
                brew upgrade
                brew install fzf gcc eza thefuck gh
                ;;
            "Oh-My-Zsh")
                echo "INFO Executing commands for Oh-My-Zsh"
                sudo apt install zsh fzf -y
                sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

                # Installs plugins
                git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
                git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
                git clone https://github.com/z-shell/zsh-eza ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-eza
                git clone --depth 1 https://github.com/unixorn/fzf-zsh-plugin.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-zsh-plugin
                git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

                echo "INFO Configuring Oh-MyZsh"
                # Backup old config file if it exists
                cp .zshrc .zshrc.backup

                # Download and replace config file
                curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/.zshrc -o ~/.zshrc
                mkdir -p ~/.fzf/shell
                touch ~/.fzf/shell/key-bindings.zsh

                source ~/.zshrc
                source ~/.zshrc
                source ~/.zshrc
                ;;
            "GEF")
                echo "INFO Executing commands for GEF"
                bash -c "$(curl -fsSL https://gef.blah.cat/sh)"
                ;;
            "apt Packages")
                echo "INFO Executing commands for apt Packages"
                sudo apt install -y python3 python3-pip git htop golang figlet irssi cmatrix neofetch cowsay fortune-mod tint smartmontools udevil samba cifs-utils mergerfs tty-clock lolcat libsass1 dpkg npm python3 needrestart lynx wget curl zsh net-tools network-manager tmux --fix-missing
                ;;
            "Casa Os")
                echo "INFO Executing commands for Casa Os"
                curl -fsSL https://get.casaos.io | sudo bash
                ;;
            "Docker")
                curl -fsSL https://test.docker.com | sh
                ;;
            *)
                echo "${WARN} Unknown option: $option"
                ;;
        esac
    done
}

# Main script logic
echo "INFO Starting the installation process..."

# Get user selections
selected_options=$(get_user_selection)

#  Convert selected options into an array (splitting by spaces)
IFS=' ' read -r -a options <<< "$selected_options"

# Execute commands based on selections
execute_commands "${options[@]}"

echo "INFO Installation process completed."
exit 0
