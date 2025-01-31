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

# Install prequisites
sudo apt update
sudo apt install -y git-core zsh curl git build-essential
# Do not print commands
set +x
echo '

    --------------- Docker Install  ---------------

'
sh -c "$(curl -fsSL https://get.docker.com)"; break;;


echo '

    --------------- Homebrew Install  ---------------

'
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Print commands
set -x

echo >> ~/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Prequises from homebrew
brew update
brew upgrade
brew install eza fzf gcc thefuck gh

# Disable exit on error 
set +eux
echo '

    --------------- Oh-My-zsh Install  ---------------

'
# Install Oh-My-zsh if not installed
#   This will install all the plugins used in our .zshrc file
if [ ! -f ~/.zshrc ]; then
  # Installs Oh-My-Zsh
  sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" | sh

  # States plugins for Oh-My-Zsh to be installed
  plugins=(
    zsh-history-substring-search
    zsh-autosuggestions
    zsh-eza
    fzf-zsh-plugin
  )

  # Install plugins
  for plugin in "${plugins[@]}"; do
    if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/$plugin" ]; then
      git clone "https://github.com/zsh-users/$plugin" "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/$plugin"
    fi
  done
fi

# Enable exit on error
set -eu
set +x
echo '

    --------------- Oh-My-zsh plugins  ---------------

'
set -x
# Backup old config file if it exists
if [ -f ~/.zshrc ]; then
    mv ~/.zshrc ~/.zshrc.backup
fi

# Download and replace config file
curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/.zshrc -o ~/.zshrc

# Setup fzf
mkdir -p ~/.fzf/shell
touch ~/.fzf/shell/key-bindings.zsh


# Source .zshrc three times only if fzf has not been initialized
if [ ! -f ~/.fzf/shell/key-bindings.zsh ]; then
    for i in {1..3}; do
        source ~/.zshrc
    done
fi

# Do not print commands
set +x
echo '

    --------------- code-server Install  ---------------

'
# Install code server
curl -fsSL https://code-server.dev/install.sh | sh

set +x
echo '

    --------------- GEF Install  ---------------

'
# Install GEF
bash -c "$(curl -fsSL https://gef.blah.cat/sh)"

# Do not print commands
set +x
echo '

    --------------- apt packages Install  ---------------

'
# Install personal apt packages
sudo apt install -y git htop golang hugo figlet irssi cmatrix neofetch cowsay fortune-mod tint tty-clock lolcat hugo libsass1 dpkg npm python3 docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin flatpak gnome-software-plugin-flatpak libcurl4-gnutls-dev bsd-mailx needrestart powermgmt-base accountsservice lynx wget curl evince zsh net-tools --fix-missing

# Print commands
set -x
sudo apt full-upgrade -y

set +x
echo '

    --------------- apt packages Install  ---------------

'
# Print commands
set -x

# Add an update-all script
sudo rm -f /usr/local/bin/update-all
sudo curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/extras/update-all%20script -o /usr/local/bin/update-all
sudo chmod +x /usr/local/bin/update-all

# Do not print commands
set +x

# Done message :)
echo "Done installing please star my repo: https://github.com/alvinlollo/Single-install-script"