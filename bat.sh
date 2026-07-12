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

    --------------- bat Install Script ---------------
  BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE UNDER THE GPL-2.0 LICENCE, THERE IS NO WARRANTY
  FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. See the LICENCE for more detail
'
fi

# Install prerequisites
if ! command -v git >/dev/null && command -v curl >/dev/null; then
  if command -v pacman >/dev/null; then
    echo "pacman detected. Installing prerequisites"
    sudo pacman -S zsh git curl --noconfirm
  fi

  if command -v apt >/dev/null; then
    echo "apt detected. Installing prerequisites"
    sudo apt install git curl -y
  fi
fi

# Install bat
if ! command -v bat >/dev/null; then
  if ! command -v zsh >/dev/null && command -v git >/dev/null && command -v curl >/dev/null && command -v fzf >/dev/null; then
    if command -v pacman >/dev/null; then
      echo "pacman detected. Installing bat"
      sudo pacman -S bat batman --noconfirm
    fi

    if command -v apt >/dev/null; then
      echo "apt detected. Installing bat"
      sudo apt install bat batman -y
    fi
  fi
  # 1. Detect the actual active shell name (not just the login default)
  CURRENT_SHELL=$(basename -- "$SHELL")

  # 2. Source the correct configuration file safely
  if [ "$CURRENT_SHELL" = "bash" ] && [ -f ~/.bashrc ]; then
    source ~/.bashrc
  elif [ "$CURRENT_SHELL" = "zsh" ] && [ -f ~/.zshrc ]; then
    source ~/.zshrc
  elif [ "$CURRENT_SHELL" = "fish" ] && [ -f ~/.config/fish/config.fish ]; then
    source ~/.config/fish/config.fish
  else
    echo "Unsupported or unreadable shell configuration: $CURRENT_SHELL"
  fi

fi

# Install Catppuccin themes
source ~/.bashrc
mkdir -p "$(bat --config-dir)/themes"
wget -P "$(bat --config-dir)/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Macchiato.tmTheme
bat cache --build

echo "--theme="Catppuccin Mocha"" >>"$(bat --config-dir)/themes"

# Detect shell name via POSIX standard
CURRENT_SHELL=$(basename "$0" 2>/dev/null || echo "$0")
CURRENT_SHELL="${CURRENT_SHELL#-}"

case "$CURRENT_SHELL" in
"bash") [ -f ~/.bashrc ] && echo "export MANPAGER="bat -plman"" >>~/.bashrc ;;
"zsh") [ -f ~/.zshrc ] && echo "export MANPAGER="bat -plman"" >>~/.zshrc ;;
"fish") exec fish -c "echo "export MANPAGER="bat -plman"" >> ~/.config/fish/config.fish" ;;
*) echo "Unsupported shell: $CURRENT_SHELL" ;;
esac
