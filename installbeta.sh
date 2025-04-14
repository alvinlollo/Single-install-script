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

# Define colors for output
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
RESET="$(tput sgr0)"

# Log file
LOG="install_$(date +%Y%m%d_%H%M%S).log"

# Function to log messages
log_message() {
    echo "$1" | tee -a "$LOG"
}

# Function to present options and get user selection
get_user_selection() {
    local options=("Homebrew" "Oh-My-Zsh" "GEF" "apt Packages" "Casa Os" "Extra scripts")
    local descriptions=("Installs homebrew using their install script" "Installs Oh-My-Zsh with plugins and configurations" "Installs GEF (https://github.com/hugsy/gef)" "Installs packages and utilities" "Installs CasaOs using install script" "Installs extra scripts see readme")
    local selections=()
    local choice
    
    clear
    echo "Please select the options you want to execute:"
    echo "Use SPACEBAR to select/unselect, TAB to navigate, and ENTER to confirm."
    echo "-------------------------------------------------------------------"

    # Build the whiptail command
    local whiptail_options=()
    whiptail_options+=("--checklist")
    whiptail_options+=("Choose options:")
    whiptail_options+=(20)  # Height of the dialog
    whiptail_options+=(70)  # Width of the dialog
    whiptail_options+=(6)   # Number of options to display

    for i in "${!options[@]}"; do
        whiptail_options+=("${options[$i]}")
        whiptail_options+=("${descriptions[$i]}")
        whiptail_options+=("OFF")  # Initial state (OFF)
    done

    # Execute whiptail and capture the result
    local selected_values
    selected_values=$(whiptail "${whiptail_options[@]}" --output-fd 3 3>&1 1>&2 2>&1)
    local result=$?

    if [ "$result" -ne 0 ]; then
        log_message "${INFO} No options selected. Exiting."
        exit 1
    fi

    IFS=$'\n' read -r -a selections <<< "$selected_values"

    echo "Selected options: ${selections[*]}"
    
    # Return the selected options
    echo "${selections[*]}"
}

# Function to execute commands based on user selection
execute_commands() {
    local selected_options=("$@")

    for option in "${selected_options[@]}"; do
        case "$option" in
            "Homebrew")
                log_message "${INFO} Executing commands for Homebrew"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
                brew update
                brew upgrade
                brew install fzf gcc eza thefuck gh
                ;;
            "Oh-My-Zsh")
                log_message "${INFO} Executing commands for Oh-My-Zsh"
                sudo apt install zsh fzf -y
                sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
                
                # Installs plugins
                git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
                git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
                git clone https://github.com/z-shell/zsh-eza ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-eza
                git clone --depth 1 https://github.com/unixorn/fzf-zsh-plugin.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-zsh-plugin
                git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
                
                log_message "${INFO} Configuring Oh-MyZsh"
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
                log_message "${INFO} Executing commands for GEF"
                bash -c "$(curl -fsSL https://gef.blah.cat/sh)"
                ;;
            "apt Packages")
                log_message "${INFO} Executing commands for apt Packages"
                sudo apt install -y python3 python3-pip git htop golang figlet irssi cmatrix neofetch cowsay fortune-mod tint smartmontools udevil samba cifs-utils mergerfs tty-clock lolcat libsass1 dpkg npm python3 needrestart lynx wget curl zsh net-tools network-manager tmux --fix-missing
                ;;
            "Casa Os")
                log_message "${INFO} Executing commands for Casa Os"
                curl -fsSL https://get.casaos.io | sudo bash
                ;;
            "Extra scripts")
                # Add an update-all script
                sudo rm -f /usr/local/bin/update-all
                sudo curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/extras/update-all%20script -o /usr/local/bin/update-all
                sudo chmod +x /usr/local/bin/update-all
                ;;
            *)
                log_message "${WARN} Unknown option: $option"
                ;;
        esac
    done
}

# Main script logic
log_message "${INFO} Starting the installation process..."

# Get user selections
selected_options=$(get_user_selection)

# Execute commands based on selections
execute_commands $selected_options

log_message "${INFO} Installation process completed."

exit 0
