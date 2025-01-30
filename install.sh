#!/usr/bin/bash

# Fail on any command.
set -eux pipefail

# art is cool man
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
sudo apt update
sudo apt upgrade
sudo apt install git-core zsh curl git build-essential

# Install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo >> ~/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Prequises from homebrew
brew update
brew upgrade
brew install eza fzf gcc thefuck gh

# Install Oh-My-zsh
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Remove old config file
rm -rf ~/.zshrc

# Replace config file
touch ~/.zshrc
echo "$(curl https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/.zshrc)" >> ~/.zshrc

# [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search

# [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# [zsh-eza](https://github.com/z-shell/zsh-eza)
git clone https://github.com/z-shell/zsh-eza.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-eza

# [fzf-zsh-plugin](https://github.com/unixorn/fzf-zsh-plugin)
git clone --depth 1 https://github.com/unixorn/fzf-zsh-plugin.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-zsh-plugin

# Setup fzf
mkdir ~/.fzf
mkdir ~/.fzf/shell
touch ~/.fzf/shell/key-bindings.zsh
source ~/.zshrc
source ~/.zshrc
source ~/.zshrc

# Install code server
curl -fsSL https://code-server.dev/install.sh | sh

# Install GEF
bash -c "$(curl -fsSL https://gef.blah.cat/sh)"

# Install personal apt packages
sudo apt install git htop golang hugo figlet irssi cmatrix neofetch cowsay fortune-mod tint tty-clock lolcat hugo libsass1 dpkg npm python3 docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin flatpak gnome-software-plugin-flatpak libcurl4-gnutls-dev bsd-mailx needrestart powermgmt-base accountsservice lynx wget curl evince zsh net-tools --fix-missing

# Add a update-all script
rm -rf /usr/local/bin/update-all | sudo bash
sudo touch /usr/local/bin/update-all
sudo chmod +x /usr/local/bin/update-all
echo "$(curl https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/extras/update-all%20script)" >> /usr/local/bin/update-all

# Done message :)
echo "Done installing"