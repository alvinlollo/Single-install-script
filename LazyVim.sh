#!/usr/bin/bash

if ! command -v pacman >/dev/null; then
    echo "Cannot proceed: Not a arch based system"
    echo "This script does not have debian support"
    echo "+ sleep 10" && sleep 10
    exit 1
fi

# Install prerequisetes
sudo pacman -S --needed --noconfirm git curl wget python3 python-pip

echo ""
echo 'This script will move your current nvim config to ~/.config/nvim.bak'
echo "Press CTRL+C within 20 secconds if you don't want these actions to be made"
sleep 20
echo ""

# Remove old backups
# Remove existing .bak directories first to ensure a clean slate
echo "   Checking for and removing old Neovim backup directories..."

# Use $HOME for reliable path expansion
if [ -e "$HOME/.config/nvim.bak" ]; then
    echo "Path $HOME/.config/nvim.bak exists. Removing..."
    rm -rf "$HOME/.config/nvim.bak"
fi

if [ -e "$HOME/.local/share/nvim.bak" ]; then
    echo "Path $HOME/.local/share/nvim.bak exists. Removing..."
    rm -rf "$HOME/.local/share/nvim.bak"
fi

if [ -e "$HOME/.local/state/nvim.bak" ]; then
    echo "Path $HOME/.local/state/nvim.bak exists. Removing..."
    rm -rf "$HOME/.local/state/nvim.bak"
fi

if [ -e "$HOME/.cache/nvim.bak" ]; then
    echo "Path $HOME/.cache/nvim.bak exists. Removing..."
    rm -rf "$HOME/.cache/nvim.bak"
fi

# Remove the current nvim config and create a new backup
echo ""
echo "   Backing up current Neovim configuration..."
if [ -d "$HOME/.config/nvim" ]; then # Check if nvim config exists before moving
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
else
    echo "No existing ~/.config/nvim found to back up."
fi

echo ""
echo "   Backing up Neovim share, state, and cache directories..."
if [ -d "$HOME/.local/share/nvim" ]; then
    mv "$HOME/.local/share/nvim" "$HOME/.local/share/nvim.bak"
fi
if [ -d "$HOME/.local/state/nvim" ]; then
    mv "$HOME/.local/state/nvim" "$HOME/.local/state/nvim.bak"
fi
if [ -d "$HOME/.cache/nvim" ]; then
    mv "$HOME/.cache/nvim" "$HOME/.cache/nvim.bak"
fi

# Remove any leftover
if [ -e "$HOME/.config/.nvim" ]; then
    echo ""
    echo "Removing ~/.config/.nvim..."
    rm -rf "$HOME/.config/.nvim"
fi

# Install LazyVim
echo ""
git clone https://github.com/alvinlollo/LazyVim "$HOME/.config/nvim"

# Dependencys for Gdoc.vim
#wget https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/requirements.txt
#pip3 install -r requirements.txt --break-system-packages && rm requirements.txt
#echo "pip3 install -r requirements.txt"
