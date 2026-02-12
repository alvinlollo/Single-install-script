#!/usr/bin/bash

skip_watermark=false
if [ "$1" = "--skip-watermark" ]; then
    skip_watermark=true
fi

if [ "$skip_watermark" = false ]; then
echo '
     ____                _       _       _       _ _
    | __ ) _   _    __ _| |_   _(_)_ __ | | ___ | | | ___
    |  _ \| | | |  / _  | \ \ / / |  _ \| |/ _ \| | |/ _ \
    | |_) | |_| | | (_| | |\ V /| | | | | | (_) | | | (_) |
    |____/ \__  |  \__ _|_| \_/ |_|_| |_|_|\___/|_|_|\___/
            |___/

    --------------- ZSH Install Script ---------------
  BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE UNDER THE GPL-2.0 LICENCE, THERE IS NO WARRANTY
  FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. See the LICENCE for more detail
'
fi

# Show disclaimer
echo "This script will backup your current zsh config if it exists "

# Enable exit on error
set -eu

# Install prerequisites if installed skips

if ! command -v zsh >/dev/null && command -v git >/dev/null && command -v curl >/dev/null && command -v fzf >/dev/null; then
  if command -v pacman >/dev/null; then
    echo "pacman detected. Installing prerequisites"
    sudo pacman -S zsh git curl fzf --noconfirm
  fi

  if command -v apt >/dev/null; then
    echo "apt detected. Installing prerequisites"
    sudo apt install git curl zsh fzf -y
  fi
fi

zsh=$(which zsh)

# Do not print commands
set +x
echo '

    --------------- Oh-My-zsh Install  ---------------

'
# Print commands
set -x

# Disable exit on error
set +eu

rm -rf ~/.oh-my-zsh

# Enable exit on error
set -eu

# Do not print commands
set +x

# Install oh-my-zsh without entering zsh
CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Print commands
set -x

# Install Oh-My-Zsh plugins
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/z-shell/zsh-eza ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-eza
git clone --depth 1 https://github.com/unixorn/fzf-zsh-plugin.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-zsh-plugin
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Disable exit on error
set +eu

# Backup old config file if it exists
cp .zshrc .zshrc{,.bak} -r

# Enable exit on error
set -eu

# Download and replace config file
curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/.zshrc -o ~/.zshrc

# Download generic fzf configuration
curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/.fzf.zsh -o ~/.fzf.zsh

# Setup fzf
mkdir -p ~/.fzf/shell
touch ~/.fzf/shell/key-bindings.zsh

# Do not print commands
set +x

# If this user's login shell is already "zsh", do not attempt to switch.
if [ "$(basename -- "$SHELL")" = "zsh" ]; then
  echo "Successfully installed zsh configuration"
  exit 0 # Exit as success
fi

if command -v chsh >/dev/null; then
  echo "chsh command does not exist."
  echo "Please change your shell manually"
  sleep 5 && exit 0
fi

echo "Changing your shell to $zsh..."

if ! echo "+ sudo -k chsh -s "$zsh" "$USER"" && sudo -k chsh -s "$zsh" "$USER"; then # -k forces password prompt
  echo "Next command may fail."
  echo "+ chsh -s $"(which zsh)" "$USER""
  chsh -s $"(which zsh)" "$USER"  # run chsh normally may fail
fi

# Check if the shell change was successful
if [ $? -ne 0 ]; then
  echo "chsh command unsuccessful. Change your default shell manually:"
  echo "chsh -s $"(which zsh)" "$USER""
else
  export SHELL="$zsh"
  echo "Shell successfully changed to '$zsh'."
fi

echo "Successfully installed zsh"
