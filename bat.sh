#!/usr/bin/bash

set -euo pipefail

# Detect fish shell and ask user to switch to bash (bash-only syntax)
if [ -n "${FISH_VERSION:-}" ] || case "${SHELL:-}" in *fish*) ;; *) false ;; esac; then
  echo "Warning: fish shell detected."
  echo "This script is written for bash and may have syntax issues under fish."
  echo "Please switch to bash first and re-run it, e.g.: bash $0"
  if [ -t 0 ] && [ -e /dev/tty ]; then
    read -r -p "Press Enter to continue anyway, or Ctrl+C to cancel..." </dev/tty || true
  fi
fi

skip_watermark=false
if [ "${1:-}" = "--skip-watermark" ]; then
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
  BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE UNDER THE GPL-2.0 LICENSE, THERE IS NO WARRANTY
  FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. See the LICENSE for more detail
'
fi

# Install prerequisites if installed skips
if ! command -v git >/dev/null || ! command -v curl >/dev/null || ! command -v wget >/dev/null; then
  if command -v pacman >/dev/null; then
    echo "pacman detected. Installing prerequisites"
    if ! sudo pacman -S --needed --noconfirm git curl wget; then
      echo "Failed to install prerequisites. Install git, curl and wget manually, then re-run this script."
      exit 1
    fi
  elif command -v apt >/dev/null; then
    echo "apt detected. Installing prerequisites"
    if ! sudo apt update || ! sudo apt install git curl wget -y; then
      echo "Failed to install prerequisites. Install git, curl and wget manually, then re-run this script."
      exit 1
    fi
  else
    echo "No supported package manager found (pacman/apt)."
    echo "Please install git, curl and wget manually, then re-run this script."
    exit 1
  fi
fi

# Install bat
if ! command -v bat >/dev/null && ! command -v batcat >/dev/null; then
  if command -v pacman >/dev/null; then
    echo "pacman detected. Installing bat"
    if ! sudo pacman -S --needed --noconfirm bat bat-extras; then
      echo "Failed to install bat. Install it manually, then re-run this script."
      exit 1
    fi
  elif command -v apt >/dev/null; then
    echo "apt detected. Installing bat"
    if ! sudo apt install bat -y; then
      echo "Failed to install bat. Install it manually, then re-run this script."
      exit 1
    fi
  else
    echo "No supported package manager found (pacman/apt)."
    echo "Please install bat manually, then re-run this script."
    exit 1
  fi
fi

# Debian/Ubuntu ship the binary as batcat, provide bat for the commands below
if ! command -v bat >/dev/null && command -v batcat >/dev/null; then
  sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat
fi

if ! command -v bat >/dev/null; then
  echo "bat is not available. Install it manually, then re-run this script."
  exit 1
fi

# Install the Catppuccin Mocha theme (downloaded and configured names must match)
BAT_CONFIG_DIR="$(bat --config-dir)"
mkdir -p "$BAT_CONFIG_DIR/themes"
if [ ! -f "$BAT_CONFIG_DIR/themes/Catppuccin Mocha.tmTheme" ]; then
  if ! wget -q -O "$BAT_CONFIG_DIR/themes/Catppuccin Mocha.tmTheme" \
    "https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme"; then
    echo "Failed to download the Catppuccin Mocha theme."
    exit 1
  fi
fi
bat cache --build

# Set the default theme in bat's config file (the themes/ directory only holds themes)
if ! grep -qxF -- '--theme="Catppuccin Mocha"' "$BAT_CONFIG_DIR/config" 2>/dev/null; then
  printf '%s\n' '--theme="Catppuccin Mocha"' >>"$BAT_CONFIG_DIR/config"
fi

# Configure the MANPAGER for the user's actual login shell ($SHELL, not $0)
CURRENT_SHELL=$(basename -- "${SHELL:-/bin/bash}")

case "$CURRENT_SHELL" in
bash)
  if [ -f "$HOME/.bashrc" ] && ! grep -qxF 'export MANPAGER="bat -plman"' "$HOME/.bashrc"; then
    printf '%s\n' 'export MANPAGER="bat -plman"' >>"$HOME/.bashrc"
  fi
  ;;
zsh)
  if [ -f "$HOME/.zshrc" ] && ! grep -qxF 'export MANPAGER="bat -plman"' "$HOME/.zshrc"; then
    printf '%s\n' 'export MANPAGER="bat -plman"' >>"$HOME/.zshrc"
  fi
  ;;
fish)
  if [ -f "$HOME/.config/fish/config.fish" ] && ! grep -qxF 'set -gx MANPAGER "bat -plman"' "$HOME/.config/fish/config.fish"; then
    printf '%s\n' 'set -gx MANPAGER "bat -plman"' >>"$HOME/.config/fish/config.fish"
  fi
  ;;
*)
  echo "Unsupported shell: $CURRENT_SHELL (skipping MANPAGER setup)"
  ;;
esac

echo "bat configured with the Catppuccin Mocha theme."
