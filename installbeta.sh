#!/bin/bash

clear
echo -e "\e[0m\c"

# shellcheck disable=SC2016
echo '
     ____                _       _       _       _ _
    |  _ \ _   _    __ _| |_   _(_)_ __ | | ___ | | | ___
    |  _ \| | | |  / _  | \ \ / / |  _ \| |/ _ \| | |/ _ \
    | |_) | |_| | | (_| | |\ V /| | | | | | (_) | | | (_) |
    |____/ \__  |  \__ _|_| \_/ |_|_| |_|_|\___/|_|_|\___/
            |___/

    --------------- Single Download script ---------------
'

# Install prerequisites
echo "Install prerequisites"
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

whiptail_options=(
    "homebrew" "Installs homebrew using the install script" "OFF"
    "ohmyzsh" "Installs Oh-My-Zsh with plugins and configurations" "ON"
    "gef" "Installs GEF (https://github.com/hugsy/gef/)" "OFF"
    "apt_packages" "Installs packages and utilities" "ON"
    "casaos" "Installs CasaOs using the install script" "OFF"
    "docker" "Installs Docker with install script" "OFF"
)

# Append options to the whiptail command
for i in "${!whiptail_options[@]}"; do
    whiptail_command+=("${whiptail_options[$i]}")
done

# Function to get user selections
get_user_selection() {
    local selections
    # Execute whiptail and capture the output
    selections=$(whiptail "${whiptail_command[@]}" 2>/dev/null)

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
            "homebrew")
                echo "INFO Executing commands for Homebrew"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || echo "ERROR Failed to install Homebrew"
                brew update || echo "ERROR Homebrew update failed"
                brew upgrade || echo "ERROR Homebrew upgrade failed"
                brew install fzf gcc eza thefuck gh || echo "ERROR Failed to install Homebrew packages"
                ;;
            "ohmyzsh")
                echo "INFO Executing commands for Oh-My-Zsh"
                sudo apt install zsh fzf -y || echo "ERROR Failed to install zsh and fzf"
                sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || echo "ERROR Failed to install Oh-My-Zsh"

                # Installs plugins
                git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search || echo "ERROR Failed to install zsh-history-substring-search"
                git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || echo "ERROR Failed to install zsh-autosuggestions"
                git clone https://github.com/z-shell/zsh-eza ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-eza || echo "ERROR Failed to install zsh-eza"
                git clone --depth 1 https://github.com/unixorn/fzf-zsh-plugin.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-zsh-plugin || echo "ERROR Failed to install fzf-zsh-plugin"
                git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || echo "ERROR Failed to install zsh-syntax-highlighting"

                echo "INFO Configuring Oh-MyZsh"

                # Backup old config file if it exists
                if [ -f ~/.zshrc ]; then
                    cp ~/.zshrc ~/.zshrc.backup || echo "ERROR Failed to backup .zshrc"
                fi

                # Download and replace config file
                curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/.zshrc -o ~/.zshrc || echo "ERROR Failed to download .zshrc"
                mkdir -p ~/.fzf/shell || echo "ERROR Failed to create .fzf/shell"
                touch ~/.fzf/shell/key-bindings.zsh || echo "ERROR Failed to create key-bindings.zsh"

                source ~/.zshrc
                source ~/.zshrc
                source ~/.zshrc
                ;;
            "gef")
                echo "INFO Executing commands for GEF"
                bash -c "$(curl -fsSL https://gef.blah.cat/sh)" || echo "ERROR Failed to install GEF"
                ;;
            "apt_packages")
                echo "INFO Executing commands for apt Packages"
                sudo apt install -y python3 python3-pip git htop golang figlet irssi cmatrix neofetch cowsay fortune-mod tint smartmontools udevil samba cifs-utils mergerfs tty-clock lolcat libsass1 dpkg npm python3 needrestart lynx wget curl zsh net-tools network-manager tmux --fix-missing || echo "ERROR Failed to install apt packages"
                ;;
            "casaos")
                echo "INFO Executing commands for Casa Os"
                curl -fsSL https://get.casaos.io | sudo bash || echo "ERROR Failed to install CasaOS"
                ;;
            "docker")
                echo "INFO Executing commands for Docker"
                curl -fsSL https://get.docker.com | sh || echo "ERROR Failed to install Docker"
                ;;
            *)
                echo "WARN Unknown option: $option"
                ;;
        esac
    done
}

# Main script logic
echo "INFO Starting the installation process..."

# Get user selections
selected_options=$(get_user_selection)

# Check if selected_options is empty
if [ -z "$selected_options" ]; then
    echo "INFO No options selected. Exiting."
    exit 1
fi

# Convert selected options into an array (splitting by space)
IFS=' ' read -r -a options <<< "$selected_options"

# Execute commands based on selections
execute_commands "${options[@]}"

echo "INFO Installation process completed."
exit 0
