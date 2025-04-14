#!/usr/bin/bash

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

# Fail on any command.
set -eux pipefail

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

# Do not print commands
set +x
set +eux
echo '

    --------------- Oh-My-zsh Install  ---------------

'
# Print commands
set -x

sudo apt install zsh fzf -y

# Installs Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  # Install plugins
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/z-shell/zsh-eza ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-eza
git clone --depth 1 https://github.com/unixorn/fzf-zsh-plugin.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-zsh-plugin
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Enable exit on error
set -eu
set +x
echo '

    --------------- Oh-My-zsh plugins  ---------------

'
set -x
# Backup old config file if it exists
cp .zshrc .zshrc.backup

# Download and replace config file
curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/.zshrc -o ~/.zshrc

# Setup fzf
mkdir -p ~/.fzf/shell
touch ~/.fzf/shell/key-bindings.zsh

# Do not print commands
set +x
echo '

    --------------- code-server Install  ---------------

'
# Install code server
# curl -fsSL https://code-server.dev/install.sh | sh
echo "Disabled"

set +x
echo '

    --------------- GEF Install  ---------------

'
set -x
# Install GEF
bash -c "$(curl -fsSL https://gef.blah.cat/sh)"

# Do not print commands
set +x
echo '

    --------------- apt packages Install  ---------------

'
set -x
# Install personal apt packages
sudo apt install -y python3 python3-pip git htop golang figlet irssi cmatrix neofetch cowsay fortune-mod tint smartmontools udevil samba cifs-utils mergerfs tty-clock lolcat libsass1 dpkg npm python3 needrestart lynx wget curl zsh net-tools network-manager tmux --fix-missing

# Print commands
set -x
sudo apt full-upgrade -y

# Add an update-all script
#sudo rm -f /usr/local/bin/update-all
#sudo curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/extras/update-all%20script -o /usr/local/bin/update-all
#sudo chmod +x /usr/local/bin/update-all

# Do not print commands
set +x

# Done message :)
echo "Done installing please star my repo: https://github.com/alvinlollo/Single-install-script"
