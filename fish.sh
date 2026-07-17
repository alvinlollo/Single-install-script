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

    --------------- FISH Install Script ---------------
  BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE UNDER THE GPL-2.0 LICENCE, THERE IS NO WARRANTY
  FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. See the LICENCE for more detail
'
fi

# Show disclaimer
echo "This script will add fish functions and install fish"

# Enable exit on error
set -eu

# Install prerequisites if installed skips

if ! command -v zsh >/dev/null && command -v git >/dev/null && command -v curl >/dev/null && command -v fzf >/dev/null; then
  if command -v pacman >/dev/null; then
    echo "pacman detected. Installing prerequisites"
    sudo pacman -S fish git curl fzf --noconfirm
  fi

  if command -v apt >/dev/null; then
    echo "apt detected. Installing prerequisites"
    sudo apt install git curl fish fzf -y
  fi
fi

# Clone or pull end-4 dotfiles repository
if [ -d dots-hyprland ]; then
  cd dots-hyprland && git pull && cd ..
else
  git clone https://github.com/end-4/dots-hyprland.git
fi

# Copy fish config files from end-4 to git repo if they don't exist
if [ ! -f configs/fish/config.fish ]; then
  cp dots-hyprland/dots/.config/fish/config.fish configs/fish/config.fish
fi

if [ ! -f configs/fish/auto-Hypr.fish ]; then
  cp dots-hyprland/dots/.config/fish/auto-Hypr.fish configs/fish/auto-Hypr.fish
fi

if [ ! -f configs/fish/fish_variables ]; then
  cp dots-hyprland/dots/.config/fish/fish_variables configs/fish/fish_variables
fi

# Copy color configs from end-4 to git repo if they don't exist
if [ ! -f configs/hypr/hyprland/colors.conf ]; then
  cp dots-hyprland/dots/.config/hypr/hyprland/colors.conf configs/hypr/hyprland/colors.conf
fi

if [ ! -f configs/hypr/hyprlock/colors.conf ]; then
  cp dots-hyprland/dots/.config/hypr/hyprlock/colors.conf configs/hypr/hyprlock/colors.conf
fi

# Run end-4 setup script with flags to skip unnecessary components
dots-hyprland/setup install --force --skip-plasmaintg --skip-backup --skip-quickshell --skip-hyprland --skip-hyprland-entry

# Create fish config directory
mkdir -p "$HOME/.config/fish"

# Copy fish config files to user config if they don't exist
if [ ! -f "$HOME/.config/fish/config.fish" ]; then
  cp configs/fish/config.fish "$HOME/.config/fish/config.fish"
fi

if [ -d configs/fish/functions ] && [ ! -d "$HOME/.config/fish/functions" ]; then
  cp -r configs/fish/functions "$HOME/.config/fish/"
fi

if [ -d configs/fish/conf.d ] && [ ! -d "$HOME/.config/fish/conf.d" ]; then
  cp -r configs/fish/conf.d "$HOME/.config/fish/"
fi

if [ ! -f "$HOME/.config/fish/auto-Hypr.fish" ]; then
  cp configs/fish/auto-Hypr.fish "$HOME/.config/fish/"
fi

# Copy color configs to user config if they don't exist
if [ ! -f "$HOME/.config/hypr/hyprland/colors.conf" ]; then
  cp configs/hypr/hyprland/colors.conf "$HOME/.config/hypr/hyprland/colors.conf"
fi

if [ ! -f "$HOME/.config/hypr/hyprlock/colors.conf" ]; then
  cp configs/hypr/hyprlock/colors.conf "$HOME/.config/hypr/hyprlock/colors.conf"
fi

# Install Fisher plugin manager for fish shell
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

# Install plugins using Fisher
fisher install jorgebucaran/nvm.fish
