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

# Install prerequisites
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
  exit 1
fi

echo ""
echo 'This script will back up your current nvim config with a timestamped name, e.g. ~/.config/nvim.bak-20261008-130000'
if [ -t 0 ]; then
  echo "Press CTRL+C within 10 seconds if you don't want these actions to be made"
  sleep 10
fi
echo ""

# Back up current nvim directories with a timestamp so a re-run never
# destroys the user's original backup (old behaviour deleted *.bak first)
STAMP="$(date +%Y%m%d-%H%M%S)"

backup_if_exists() {
  local src="$1"
  if [ -e "$src" ]; then
    echo "   Backing up $src -> ${src}.bak-$STAMP"
    mv "$src" "${src}.bak-$STAMP"
  fi
}

echo "   Backing up current Neovim configuration..."
backup_if_exists "$HOME/.config/nvim"
backup_if_exists "$HOME/.local/share/nvim"
backup_if_exists "$HOME/.local/state/nvim"
backup_if_exists "$HOME/.cache/nvim"

# Remove any leftover
if [ -e "$HOME/.config/.nvim" ]; then
  echo ""
  echo "Removing ~/.config/.nvim..."
  rm -rf "$HOME/.config/.nvim"
fi

# Install LazyVim
echo ""
if ! git clone https://github.com/alvinlollo/LazyVim "$HOME/.config/nvim"; then
  echo "error: failed to clone https://github.com/alvinlollo/LazyVim into ~/.config/nvim" >&2
  echo "Your previous config is preserved in ~/.config/nvim.bak-$STAMP (if one existed)." >&2
  exit 1
fi

# Load nvm into this shell if it exists. nvm is a shell function, so
# 'command -v nvm' only works after its init script has been sourced.
NVM_LOADED=false
for nvm_init in "$HOME/.nvm/nvm.sh" /usr/share/nvm/nvm.sh /usr/share/nvm/init-nvm.sh; do
  if [ -f "$nvm_init" ]; then
    set +u # nvm's init script is not always nounset-safe
    # shellcheck disable=SC1090
    if ! . "$nvm_init"; then
      set -u
      continue # try the next candidate
    fi
    set -u
    NVM_LOADED=true
    break
  fi
done

CURRENT_SHELL=$(basename -- "${SHELL:-/bin/bash}")

case "$CURRENT_SHELL" in
fish)
  # fish cannot source nvm.sh - it uses the nvm.fish plugin instead
  if [ -f "$HOME/.config/fish/config.fish" ]; then
    if ! fish -c 'type -q fisher' 2>/dev/null; then
      fisher_src="$(mktemp)"
      if ! curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish -o "$fisher_src"; then
        echo "error: failed to download fisher.fish" >&2
        rm -f "$fisher_src"
        exit 1
      fi
      fish -c "source '$fisher_src' && fisher install jorgebucaran/fisher"
      rm -f "$fisher_src"
    fi
    fish -c 'fisher install jorgebucaran/nvm.fish'
  else
    echo "No ~/.config/fish/config.fish found, skipping fish plugin setup"
  fi
  ;;
zsh)
  if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q 'nvm.sh' "$HOME/.zshrc"; then
      printf '%s\n' \
        'export NVM_DIR="$HOME/.nvm"' \
        '[ -s "/usr/share/nvm/nvm.sh" ] && . "/usr/share/nvm/nvm.sh"' \
        '[ -s "/usr/share/nvm/init-nvm.sh" ] && . "/usr/share/nvm/init-nvm.sh"' >>"$HOME/.zshrc"
    fi
  else
    echo "No ~/.zshrc found, skipping nvm shell wiring"
  fi
  ;;
bash)
  if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q 'nvm.sh\|init-nvm.sh' "$HOME/.bashrc"; then
      printf '%s\n' \
        'export NVM_DIR="$HOME/.nvm"' \
        '[ -s "/usr/share/nvm/nvm.sh" ] && . "/usr/share/nvm/nvm.sh"' \
        '[ -s "/usr/share/nvm/init-nvm.sh" ] && . "/usr/share/nvm/init-nvm.sh"' >>"$HOME/.bashrc"
    fi
  else
    echo "No ~/.bashrc found, skipping nvm shell wiring"
  fi
  ;;
*)
  echo "Unsupported or unreadable shell configuration: $CURRENT_SHELL"
  echo "Failed to add NVM to shell path. Please add it manually to your shell configuration file."
  ;;
esac

# Use nvm (when loaded) to install the latest LTS version of Node.js
if [ "$NVM_LOADED" = true ]; then
  nvm install lts
  nvm use lts
elif command -v node >/dev/null; then
  echo "nvm not available, using system Node.js $(node --version)"
else
  echo "No Node.js installation found."
  echo "Install nvm (Arch: pacman -S nvm) or nodejs, then re-run this script."
  exit 1
fi

echo "LazyVim setup complete."
