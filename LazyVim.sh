#!/usr/bin/bash

if ! command -v pacman >/dev/null; then
  echo "Cannot proceed: Not a arch based system"
  echo "This script does not have debian support"
  echo "+ sleep 10" && sleep 10
  exit 1
fi

# Install prerequisetes
sudo pacman -S --needed --noconfirm git curl wget python3 python-pip neovim jdk-openjdk base-devel ripgrep fd lazygit curl tectonic tree-sittter sclip julia luarocks shfmt ast-grep nvm

echo ""
echo 'This script will move your current nvim config to ~/.config/nvim.bak'
echo "Press CTRL+C within 10 secconds if you don't want these actions to be made"
sleep 10
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
git clone https://github.com/alvinlollo/LazyVim ~/.config/nvim

# Check if nvm is in shell path
if command -v nvm &>/dev/null; then
  # Get current shell name
  CURRENT_SHELL=$(basename -- "$SHELL")

  # 2. Source the correct configuration file safely
  if [ "$CURRENT_SHELL" = "fish" ] && [ -f ~/.bashrc ]; then

    # Check if fish is installed first, then check for fisher
    if command -v fish &>/dev/null && fish -c "functions -q fisher" &>/dev/null; then
      fisher install jorgebucaran/nvm.fish
    else
      curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
      fisher install jorgebucaran/fisher
      source ~/.fishrc
    fi

  elif [ "$CURRENT_SHELL" = "zsh" ] && [ -f ~/.zshrc ]; then

    echo -e "export NVM_DIR=\"$HOME/.nvm\"\n[ -s \"/usr/share/nvm/nvm.sh\" ] && \. \"/usr/share/nvm/nvm.sh\"\n[ -s \"/usr/share/nvm/init-nvm.sh\" ] && \. \"/usr/share/nvm/init-nvm.sh\"" >>~/.zshrc
    source ~/.zshrc

  elif [ "$CURRENT_SHELL" = "bash" ] && [ -f ~/.config/fish/config.fish ]; then

    echo "source /usr/share/nvm/init-nvm.sh" >>~/.bashrc
    source ~/.bashrc

  else
    echo "Unsupported or unreadable shell configuration: $CURRENT_SHELL"
    echo "Failed to add NVM to shell path. Please add it manually to your shell configuration file."
  fi
fi

# Use NVM to install the latest LTS version of Node.js
nvm install lts
nvm use lts
