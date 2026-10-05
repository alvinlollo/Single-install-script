#!/usr/bin/bash

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

    --------------- ZSH Install Script ---------------
  BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE UNDER THE GPL-2.0 LICENCE, THERE IS NO WARRANTY
  FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. See the LICENCE for more detail
'
fi

# Show disclaimer
echo "This script will backup your current zsh config if it exists "

# Enable exit on error
set -eu

# Install prerequisites if any of them is missing
if ! command -v zsh >/dev/null || ! command -v git >/dev/null || ! command -v curl >/dev/null || ! command -v fzf >/dev/null; then
  if command -v pacman >/dev/null; then
    echo "pacman detected. Installing prerequisites"
    sudo pacman -S zsh git curl fzf --noconfirm
  fi

  if command -v apt >/dev/null; then
    echo "apt detected. Installing prerequisites"
    sudo apt install git curl zsh fzf -y
  fi
fi

if ! command -v zsh >/dev/null; then
  echo "error: zsh could not be installed (no supported package manager, or install failed)." >&2
  echo "Install zsh manually, then re-run this script." >&2
  exit 1
fi

zsh=$(command -v zsh)

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

# Backup the user's current config before oh-my-zsh overwrites it
if [ -f "$HOME/.zshrc" ]; then
  if ! cp "$HOME/.zshrc" "$HOME/.zshrc.bak"; then
    echo "error: failed to back up $HOME/.zshrc to $HOME/.zshrc.bak" >&2
    exit 1
  fi
  echo "Backed up $HOME/.zshrc to $HOME/.zshrc.bak"
fi

# Install oh-my-zsh without entering zsh
if ! omz_installer=$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh); then
  echo "error: could not download the oh-my-zsh installer" >&2
  exit 1
fi
CHSH=no sh -c "$omz_installer" "" --unattended

# Print commands
set -x

# Install Oh-My-Zsh plugins
# Note: use $HOME, not ~ inside ${VAR:-...} — tilde is not expanded there,
# which would clone into a literal ./~ directory.
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
clone_plugin() {
  local dest="$1"
  shift
  if ! git clone "$@" "$dest"; then
    echo "warning: failed to clone into $dest (skipping)" >&2
  fi
}
clone_plugin "$ZSH_CUSTOM_DIR/plugins/zsh-history-substring-search" https://github.com/zsh-users/zsh-history-substring-search.git
clone_plugin "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" https://github.com/zsh-users/zsh-autosuggestions.git
clone_plugin "$ZSH_CUSTOM_DIR/plugins/zsh-eza" https://github.com/z-shell/zsh-eza.git
clone_plugin "$ZSH_CUSTOM_DIR/plugins/fzf-zsh-plugin" --depth=1 https://github.com/unixorn/fzf-zsh-plugin.git
clone_plugin "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" https://github.com/zsh-users/zsh-syntax-highlighting.git
clone_plugin "$ZSH_CUSTOM_DIR/plugins/zsh-autocomplete" --depth=1 https://github.com/marlonrichert/zsh-autocomplete.git


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
user_name="${USER:-${LOGNAME:-$(id -un)}}"
if command -v getent >/dev/null 2>&1; then
  login_shell="$(getent passwd "$user_name" | awk -F: '{print $7}' | tr -d '\n')"
else
  login_shell="$(grep -E "^${user_name}:" /etc/passwd | awk -F: '{print $7}' | tr -d '\n' || true)"
fi

if [ -z "${login_shell:-}" ]; then
  login_shell="${SHELL:-}"
fi

if [ "$(basename -- "${login_shell:-}")" = "zsh" ]; then
  echo "You already have zsh as the default shell"
  echo "Successfully installed zsh configuration"
  exit 0 # Exit as success
fi

if ! command -v chsh >/dev/null; then
  echo "chsh command does not exist."
  echo "Please change your shell manually:"
  echo "chsh -s \"$zsh\""
  echo "Successfully installed zsh configuration"
  exit 0
fi

echo "Changing your shell to $zsh..."

echo "+ sudo -k chsh -s \"$zsh\" \"$user_name\""
if sudo -k chsh -s "$zsh" "$user_name"; then # -k forces password prompt
  export SHELL="$zsh"
  echo "Shell successfully changed to '$zsh'."
else
  echo "sudo chsh failed. Trying without sudo (this may fail):"
  echo "+ chsh -s \"$zsh\" \"$user_name\""
  if chsh -s "$zsh" "$user_name"; then
    export SHELL="$zsh"
    echo "Shell successfully changed to '$zsh'."
  else
    echo "chsh command unsuccessful. Change your default shell manually:"
    echo "chsh -s \"$zsh\" \"$user_name\""
  fi
fi

echo "Successfully installed zsh"
