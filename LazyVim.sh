#!/usr/bin/bash

# Detect fish shell and ask user to switch to bash (bash-only syntax)
if [ -n "${FISH_VERSION:-}" ] || case "$SHELL" in *fish*) ;; *) false ;; esac; then
  echo "Warning: fish shell detected."
  echo "This script is written for bash and may have syntax issues under fish."
  echo "Please switch to bash first and re-run it, e.g.: bash $0"
  read -r -p "Press Enter to continue anyway, or Ctrl+C to cancel..." </dev/tty || true
fi

# Install prerequisetes
if command -v pacman >/dev/null; then
  echo "pacman detected. Installing prerequisites"
  # sclip is not packaged for arch, tree-sitter-cli ships the tree-sitter binary
  if ! sudo pacman -S --needed --noconfirm git curl wget python3 python-pip neovim jdk-openjdk base-devel ripgrep fd lazygit tectonic tree-sitter-cli julia luarocks shfmt ast-grep nvm nodejs; then
    echo "--------------------------------------------------------------------"
    echo "Failed to install prerequisites. You can try running it manually:"
    echo "sudo pacman -S --needed --noconfirm git curl wget python3 python-pip neovim jdk-openjdk base-devel ripgrep fd lazygit tectonic tree-sitter-cli julia luarocks shfmt ast-grep nvm nodejs"
    echo "--------------------------------------------------------------------"
    exit 1
  fi
elif command -v apt >/dev/null; then
  echo "apt detected. Installing prerequisites"
  # tectonic and sclip have no debian package, ast-grep comes from npm, node comes from nodejs
  if ! sudo apt update || ! sudo apt install git curl wget python3 python3-pip python3-pynvim neovim default-jdk build-essential ripgrep fd-find luarocks shfmt nodejs npm -y; then
    echo "--------------------------------------------------------------------"
    echo "Failed to install prerequisites. You can try running it manually:"
    echo "sudo apt install git curl wget python3 python3-pip python3-pynvim neovim default-jdk build-essential ripgrep fd-find luarocks shfmt nodejs npm -y"
    echo "--------------------------------------------------------------------"
    exit 1
  fi

  # lazygit and tree-sitter-cli only exist on the newest releases, julia is missing on some architectures (e.g. arm64)
  for optional_pkg in lazygit tree-sitter-cli julia; do
    sudo apt install "$optional_pkg" -y || echo "$optional_pkg could not be installed, skipping"
  done

  # Debian ships the fd binary as fdfind
  if ! command -v fd >/dev/null && command -v fdfind >/dev/null; then
    sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
  fi

  if ! command -v ast-grep >/dev/null; then
    sudo npm install -g @ast-grep/cli || echo "ast-grep could not be installed, skipping"
  fi

  echo "Skipped on debian (not packaged): tectonic, sclip"
else
  echo "Cannot proceed: pacman or apt is required"
  echo "This script supports arch based and debian based systems"
  echo "+ sleep 10" && sleep 10
  exit 1
fi

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
      source ~/.config/fish/config.fish
    else
      curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
      fisher install jorgebucaran/fisher
      fisher install jorgebucaran/nvm.fish
      source ~/.config/fish/config.fish
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
if command -v nvm &>/dev/null; then
  nvm install lts
  nvm use lts
elif command -v node >/dev/null; then
  echo "nvm not found, using system Node.js $(node --version)"
else
  echo "No Node.js installation found."
  echo "Source your nvm install (e.g. . /usr/share/nvm/nvm.sh) or install nodejs, then re-run this script."
  exit 1
fi
