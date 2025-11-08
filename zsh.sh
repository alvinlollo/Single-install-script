#!/usr/bin/bash

echo '
     ____                _       _       _       _ _
    | __ ) _   _    __ _| |_   _(_)_ __ | | ___ | | | ___
    |  _ \| | | |  / _  | \ \ / / |  _ \| |/ _ \| | |/ _ \
    | |_) | |_| | | (_| | |\ V /| | | | | | (_) | | | (_) |
    |____/ \__  |  \__ _|_| \_/ |_|_| |_|_|\___/|_|_|\___/
            |___/

    --------------- ZSH Install Script ---------------
'

# Enable exit on error
set -eu

# Install prerequisites

if command -v pacman >/dev/null; then
  echo "pacman detected. Installing prerequisites"
  sudo pacman -S zsh git curl fzf --no-confirm
fi

if command -v apt >/dev/null; then
  echo "apt detected. Installing prerequisites"
  sudo apt install git curl zsh fzf -y
fi

# Do not print commands
set +x
echo '

    --------------- Oh-My-zsh Install  ---------------

'
# Print commands
set -x


# Backup old config file if it exists
cp .zshrc .zshrc.backup

# Download and replace config file
curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/.zshrc -o ~/.zshrc

# Download generic fzf configuration
curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/.fzf.zsh -o ~/.fzf.zsh

# Setup fzf
mkdir -p ~/.fzf/shell
touch ~/.fzf/shell/key-bindings.zsh

# Disable exit on error
set +eu

# Move existing oh-my-zsh installation
mv ~/.oh-my-zsh ~/oh-my-zsh-backup

# Enable exit on error
set -eu

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Oh-My-Zsh plugins
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/z-shell/zsh-eza ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-eza
git clone --depth 1 https://github.com/unixorn/fzf-zsh-plugin.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-zsh-plugin
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Enable exit on error
set -eu

chsh -s $(which zsh)
