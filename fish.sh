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

    --------------- FISH Install Script ---------------
  BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE UNDER THE GPL-2.0 LICENSE, THERE IS NO WARRANTY
  FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. See the LICENSE for more detail
'
fi

# Show disclaimer
echo "This script will add fish functions and install fish"

# Resolve where this script (and its configs/) live. When the script arrives
# over a pipe (curl | bash) there is no local checkout, so repo-config syncing
# is skipped and only the user's home directory is populated.
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  SCRIPT_DIR=""
fi

# Never clone or write into the caller's current directory
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# Install prerequisites if any of them are missing
if ! command -v fish >/dev/null || ! command -v git >/dev/null ||
  ! command -v curl >/dev/null || ! command -v fzf >/dev/null; then
  if command -v pacman >/dev/null; then
    echo "pacman detected. Installing prerequisites"
    if ! sudo pacman -S --needed --noconfirm fish git curl fzf; then
      echo "Failed to install prerequisites (fish, git, curl, fzf). Install them manually, then re-run this script."
      exit 1
    fi
  elif command -v apt >/dev/null; then
    echo "apt detected. Installing prerequisites"
    if ! sudo apt update || ! sudo apt install git curl fish fzf -y; then
      echo "Failed to install prerequisites (fish, git, curl, fzf). Install them manually, then re-run this script."
      exit 1
    fi
  else
    echo "No supported package manager found (pacman/apt)."
    echo "Please install fish, git, curl and fzf manually, then re-run this script."
    exit 1
  fi
fi

if ! command -v fish >/dev/null; then
  echo "error: fish could not be installed (no supported package manager, or install failed)." >&2
  echo "Install fish manually, then re-run this script." >&2
  exit 1
fi

# Clone the end-4 dotfiles repository into the temp workspace
if ! git clone --depth=1 https://github.com/end-4/dots-hyprland.git "$WORK_DIR/dots-hyprland"; then
  echo "error: failed to clone https://github.com/end-4/dots-hyprland.git" >&2
  exit 1
fi

# Sync fresh end-4 files into this repo's configs/ (only when running from a
# local checkout, and only for files that do not exist yet)
if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/configs" ]; then
  for rel in \
    fish/config.fish \
    fish/auto-Hypr.fish \
    fish/fish_variables \
    hypr/hyprland/colors.conf \
    hypr/hyprlock/colors.conf; do
    if [ ! -f "$SCRIPT_DIR/configs/$rel" ] && [ -f "$WORK_DIR/dots-hyprland/dots/.config/$rel" ]; then
      mkdir -p "$(dirname "$SCRIPT_DIR/configs/$rel")"
      cp "$WORK_DIR/dots-hyprland/dots/.config/$rel" "$SCRIPT_DIR/configs/$rel"
    fi
  done
fi

# Run end-4 setup script with flags to skip unnecessary components
echo "WARNING: the end-4 installer runs with --force and --skip-backup;"
echo "it may overwrite an existing Hyprland configuration without a backup."
(
  cd "$WORK_DIR/dots-hyprland"
  ./setup install --force --skip-plasmaintg --skip-backup --skip-quickshell --skip-hyprland --skip-hyprland-entry
)

# Resolve a config file: prefer this repo's copy, fall back to the end-4 clone
cfg_src() {
  local rel="$1"
  if [ -n "$SCRIPT_DIR" ] && [ -e "$SCRIPT_DIR/configs/$rel" ]; then
    printf '%s\n' "$SCRIPT_DIR/configs/$rel"
  elif [ -e "$WORK_DIR/dots-hyprland/dots/.config/$rel" ]; then
    printf '%s\n' "$WORK_DIR/dots-hyprland/dots/.config/$rel"
  else
    return 1
  fi
}

# Copy a config file into $HOME if it does not exist yet
install_file() {
  local rel="$1" dest="$2" src
  if [ -e "$dest" ]; then
    return 0
  fi
  if ! src="$(cfg_src "$rel")"; then
    echo "warning: $rel not found in configs/ or the end-4 clone, skipping" >&2
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
}

# Copy fish config files to user config if they don't exist
install_file fish/config.fish "$HOME/.config/fish/config.fish"
install_file fish/auto-Hypr.fish "$HOME/.config/fish/auto-Hypr.fish"

if cfg_src fish/functions >/dev/null 2>&1 && [ ! -d "$HOME/.config/fish/functions" ]; then
  mkdir -p "$HOME/.config/fish"
  cp -r "$(cfg_src fish/functions)" "$HOME/.config/fish/"
fi

if cfg_src fish/conf.d >/dev/null 2>&1 && [ ! -d "$HOME/.config/fish/conf.d" ]; then
  mkdir -p "$HOME/.config/fish"
  cp -r "$(cfg_src fish/conf.d)" "$HOME/.config/fish/"
fi

# Copy color configs to user config if they don't exist
install_file hypr/hyprland/colors.conf "$HOME/.config/hypr/hyprland/colors.conf"
install_file hypr/hyprlock/colors.conf "$HOME/.config/hypr/hyprlock/colors.conf"

# Install Fisher plugin manager + plugins, running inside fish (this is bash)
if ! curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish \
  -o "$WORK_DIR/fisher.fish"; then
  echo "error: failed to download the fisher.fish installer" >&2
  exit 1
fi

if ! fish -c "source '$WORK_DIR/fisher.fish' && fisher install jorgebucaran/fisher jorgebucaran/nvm.fish"; then
  echo "error: failed to install Fisher and nvm.fish into fish" >&2
  exit 1
fi

echo "fish setup complete."
