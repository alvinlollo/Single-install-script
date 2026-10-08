#!/usr/bin/bash

# Strict mode from the very start: every tolerated failure in this script is
# an explicit guard (if ! / || record_failure), so preamble steps are checked
# too. -E (errtrace) makes the ERR trap fire inside helper functions as well.
set -Eeuo pipefail

skip_watermark=false
if [ "${1:-}" = "--skip-watermark" ]; then
  skip_watermark=true
fi

# Detect fish shell and warn user to run with bash instead (bash-only syntax)
if [ -n "${FISH_VERSION:-}" ] || case "${SHELL:-}" in *fish*) ;; *) false ;; esac; then
  if command -v gum >/dev/null; then
    if ! gum confirm "$(printf 'Your default shell appears to be fish.\n\nThis script must be run with bash. It uses bash-only syntax and will fail under fish.\n\nRun it with:\n  bash installbeta.sh\n\nContinue anyway?')"; then
      echo "Aborted. Please run this script with bash, not fish. e.g.: bash installbeta.sh"
      exit 1
    fi
  else
    echo "Warning: fish shell detected."
    echo "This script must be run with bash, not fish (bash-only syntax)."
    echo "Please run it with bash, e.g.: bash installbeta.sh"
    if [ -t 0 ] && [ -e /dev/tty ]; then
      read -r -p "Press Enter to continue anyway, or Ctrl+C to cancel..." </dev/tty || true
    fi
  fi
fi

if [ "$skip_watermark" = false ]; then
  clear 2>/dev/null || true
  echo '
     ____                _       _       _       _ _
    | __ ) _   _    __ _| |_   _(_)_ __ | | ___ | | | ___
    |  _ \| | | |  / _  | \ \ / / |  _ \| |/ _ \| | |/ _ \
    | |_) | |_| | | (_| | |\ V /| | | | | | (_) | | | (_) |
    |____/ \__  |  \__ _|_| \_/ |_|_| |_|_|\___/|_|_|\___/ 
            |___/ 

    --------------- Single Download script --------------- 
BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE UNDER THE GPL-2.0 LICENCE, 
THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. 
See the LICENCE for more detail
'
fi

# Report errors with context (line + failing command), and only once strict
# mode is active so preamble failures abort instead of printing and continuing
function error_handler() {
  local rc="$1" line="$2" cmd="$3"
  set +x
  echo ""
  echo "An error occurred (exit status $rc) at line $line while running:"
  echo "  $cmd"
  echo "Please check the output above for details."
}

# Trap errors (after set -euo pipefail above)
trap 'error_handler "$?" "$LINENO" "$BASH_COMMAND"' ERR

# --- Failure handling & full console log ------------------------------------
# Everything from here on is teed to a log file in /tmp, and Arch-only step
# failures are recorded instead of aborting the rest of the installation.
TTY_OK=false
if [ -t 1 ]; then
  TTY_OK=true
fi

# One timestamp for both files, mktemp so the names are not predictable
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$(mktemp "/tmp/installbeta-$STAMP-XXXXXX.log")"
REPORT="$(mktemp "/tmp/installbeta-failures-$STAMP-XXXXXX.txt")"
FAILED=()

exec > >(tee -a "$LOG") 2>&1

# gum draws its TUI on stderr - keep that on the real terminal, not the log pipe
gum_tty() {
  if [ "$TTY_OK" = true ]; then
    gum "$@" 2>/dev/tty
  else
    gum "$@"
  fi
}

# Record a failed step: remember it, print it now, keep installing
record_failure() {
  FAILED+=("$1 — $2")
  echo "!! FAILED: $1 — $2  (continuing with the rest of the installation)"
  echo "$(date '+%F %T')  $1 — $2" >>"$REPORT"
}

# Private temp workspace for downloads and clones. Predictable names in /tmp
# are a symlink attack vector on multi-user systems; the trap cleans up too.
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# Resolve where this script lives so local script/config fallbacks do not
# depend on the caller's current directory. Empty when piped (curl | bash).
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  SCRIPT_DIR=""
fi

# Install shelly as a dependency if not present (Arch-based)
if command -v pacman >/dev/null; then
  # Install build prerequisites for shelly
  if ! sudo pacman -S --needed --noconfirm base-devel git; then
    echo "--------------------------------------------------------------------"
    echo "Failed to install prerequisite packages for Shelly. You can try running it manually:"
    echo "sudo pacman -S --needed --noconfirm base-devel git"
    echo "--------------------------------------------------------------------"
    record_failure "Shelly bootstrap (Arch-only)" "failed to install base-devel/git prerequisites"
  fi
  # Check if shelly binary exists
  if ! command -v shelly >/dev/null; then
    echo "shelly is NOT installed. Running installation commands..."
    if ! git clone https://aur.archlinux.org/shelly.git "$WORK_DIR/shelly"; then
      echo "--------------------------------------------------------------------"
      echo "Failed to clone shelly repository. You can try running it manually:"
      echo "git clone https://aur.archlinux.org/shelly.git \"$WORK_DIR/shelly\""
      echo "--------------------------------------------------------------------"
      record_failure "Shelly bootstrap (Arch-only)" "failed to clone the shelly AUR repository"
    elif ! (cd "$WORK_DIR/shelly" && makepkg -si --noconfirm); then
      echo "--------------------------------------------------------------------"
      echo "Failed to build and install shelly. You can try running it manually:"
      echo "cd \"$WORK_DIR/shelly\" && makepkg -si --noconfirm"
      echo "--------------------------------------------------------------------"
      record_failure "Shelly bootstrap (Arch-only)" "failed to build shelly with makepkg"
    fi
  else
    echo "Shelly is already installed."
  fi
fi

# Install prerequisites
if command -v shelly >/dev/null; then
  echo "Shelly detected. Installing prerequisites"
  shelly install standard git zsh curl wget libnewt rsync gum --upgrade --no-confirm ||
    record_failure "Prerequisites (shelly)" "installing base packages via shelly failed"
fi

if command -v apt >/dev/null; then
  echo "apt detected. Installing prerequisites"
  sudo apt update || record_failure "Prerequisites (apt)" "apt update failed"
  sudo apt full-upgrade -y || record_failure "Prerequisites (apt)" "apt full-upgrade failed"
  sudo apt install git zsh curl wget rsync gum -y ||
    record_failure "Prerequisites (apt)" "apt install of base packages failed"
fi

# Ensure gum is installed
if ! command -v gum >/dev/null; then
  echo "gum is not installed. Installing it now..."

  if command -v shelly >/dev/null; then
    echo "shelly detected. Installing gum"
    shelly install standard gum --no-confirm || {
      echo "Failed to install gum. Exiting."
      exit 1
    }
  fi

  if command -v apt >/dev/null; then
    echo "apt detected. Installing gum"
    sudo apt install gum -y || {
      echo "Failed to install gum. Exiting."
      exit 1
    }
  fi

fi

# Options for the gum menu
OPTIONS=(
  "Run zsh setup script"
  "Run fish setup script"
  "Run LazyVim setup script"
  "Install Docker"
  "Install Standard Packages (Shelly)"
  "Install AUR Packages (Shelly)"
  "Install affinity with GUI"
  "Run bat setup script"
)

# Present the menu: gum when available, plain numbered fallback otherwise
# (systems with neither shelly nor apt never get gum installed - the menu
# must still work there instead of failing with a misleading message)
select_options() {
  if command -v gum >/dev/null; then
    gum_tty choose --no-limit --height 14 \
      --header "Tab = select, Enter = confirm:" \
      --selected "Run fish setup script,Install Standard Packages (Shelly),Install AUR Packages (Shelly),Run bat setup script" \
      "${OPTIONS[@]}"
    return
  fi

  echo "gum is not installed and could not be installed on this system." >&2
  echo "Falling back to a plain numbered menu." >&2
  local i=1 opt
  for opt in "${OPTIONS[@]}"; do
    printf '  %d) %s\n' "$i" "$opt"
    i=$((i + 1))
  done

  local reply=""
  if [ -e /dev/tty ]; then
    read -r -p "Enter numbers separated by spaces (Enter = cancel): " reply </dev/tty || reply=""
  else
    echo "No interactive terminal available, cannot show a menu." >&2
    return 2
  fi

  [ -n "$reply" ] || return 1

  local -a picked=()
  local n
  for n in $reply; do
    case "$n" in
    '' | *[!0-9]*)
      echo "Invalid selection: $n" >&2
      return 1
      ;;
    esac
    if [ "$n" -ge 1 ] && [ "$n" -le "${#OPTIONS[@]}" ]; then
      picked+=("${OPTIONS[$((n - 1))]}")
    else
      echo "Selection out of range: $n" >&2
      return 1
    fi
  done
  [ "${#picked[@]}" -gt 0 ] || return 1
  printf '%s\n' "${picked[@]}"
}

if ! CHOICE="$(select_options)"; then
  echo "No options selected (menu cancelled or unavailable). Nothing was installed."
  exit 1
fi

echo "User selected:"
echo "$CHOICE"

# Process selected options in menu order
while IFS= read -r selection; do
  # Skip options the user did not select
  grep -qxF "$selection" <<<"$CHOICE" || continue
  case "$selection" in
  "Run zsh setup script")
    echo "Running zsh setup script..."
    # Runs local script unless it does not exist (SCRIPT_DIR, not CWD)
    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/zsh.sh" ]; then
      echo "Found local script, running..."
      bash "$SCRIPT_DIR/zsh.sh" --skip-watermark || {
        rc=$?
        record_failure "Run zsh setup script" "zsh.sh exited with status $rc"
      }
    else
      curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/zsh.sh | bash -s -- --skip-watermark || {
        rc=$?
        record_failure "Run zsh setup script" "downloaded zsh.sh exited with status $rc"
      }
    fi
    ;;
  "Run fish setup script")
    echo "Running fish setup script..."
    # Runs local script unless it does not exist (SCRIPT_DIR, not CWD)
    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/fish.sh" ]; then
      echo "Found local script, running..."
      bash "$SCRIPT_DIR/fish.sh" --skip-watermark || {
        rc=$?
        record_failure "Run fish setup script" "fish.sh exited with status $rc"
      }
    else
      curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/fish.sh | bash -s -- --skip-watermark || {
        rc=$?
        record_failure "Run fish setup script" "downloaded fish.sh exited with status $rc"
      }
    fi
    ;;
  "Run LazyVim setup script")
    echo "Running LazyVim setup script..."
    # Runs local script unless it does not exist (SCRIPT_DIR, not CWD)
    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/LazyVim.sh" ]; then
      echo "Found local script, running..."
      bash "$SCRIPT_DIR/LazyVim.sh" || {
        rc=$?
        record_failure "Run LazyVim setup script" "LazyVim.sh exited with status $rc"
      }
    else
      curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/LazyVim.sh | bash || {
        rc=$?
        record_failure "Run LazyVim setup script" "downloaded LazyVim.sh exited with status $rc"
      }
    fi
    ;;
  "Install Docker")
    echo "Installing Docker..."
    if ! command -v docker >/dev/null; then
      echo "docker is NOT installed. Installing..."
      if curl -fsSL https://get.docker.com -o "$WORK_DIR/get-docker.sh" &&
        sh "$WORK_DIR/get-docker.sh"; then
        sudo usermod -aG docker "$USER" ||
          record_failure "Install Docker" "adding $USER to the docker group failed"
      else
        rc=$?
        record_failure "Install Docker" "docker installer script exited with status $rc"
      fi
    else
      sudo usermod -aG docker "$USER" ||
        record_failure "Install Docker" "adding $USER to the docker group failed"
      echo "Docker is already installed."
      echo "+ sleep 10" && sleep 10
    fi
    ;;
  "Install Standard Packages (Shelly)")
    echo "Installing Standard Packages via Shelly backup..."
    # Check if shelly binary is installed
    if ! command -v shelly >/dev/null; then
      echo "Cannot proceed: shelly binary not found (Arch-only)"
      record_failure "Install Standard Packages (Shelly)" "shelly binary not found (Arch-only)"
    # Install standard packages from shelly backup
    # Runs local script unless it does not exist (SCRIPT_DIR, not CWD)
    elif [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/configs/shelly-standard.toml" ]; then
      echo "Found local backup"
      shelly backup --import --name shelly-standard --directory "$SCRIPT_DIR/configs" --no-confirm || {
        rc=$?
        record_failure "Install Standard Packages (Shelly)" "shelly backup import exited with status $rc"
      }
    elif ! curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-standard.toml -o "$WORK_DIR/shelly-standard.toml"; then
      echo "--------------------------------------------------------------------"
      echo "Failed to download shelly backup. You can try running it manually:"
      echo "curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-standard.toml -o \"$WORK_DIR/shelly-standard.toml\""
      echo "--------------------------------------------------------------------"
      record_failure "Install Standard Packages (Shelly)" "failed to download shelly-standard.toml"
      echo "+ sleep 10" && sleep 10
    elif ! shelly backup --import --name shelly-standard --directory "$WORK_DIR" --no-confirm; then
      echo "--------------------------------------------------------------------"
      echo "Failed to install Standard packages. You can try running it manually:"
      echo "shelly backup --import --name shelly-standard --directory \"$WORK_DIR\" --no-confirm"
      echo "--------------------------------------------------------------------"
      record_failure "Install Standard Packages (Shelly)" "shelly backup import failed"
      echo "+ sleep 10" && sleep 10
    fi
    ;;
  "Install AUR Packages (Shelly)")
    echo "Installing AUR Packages via Shelly backup..."
    # Check for shelly before installing AUR packages
    if ! command -v shelly >/dev/null; then
      echo "Cannot proceed: shelly binary not found (Arch-only)"
      record_failure "Install AUR Packages (Shelly)" "shelly binary not found (Arch-only)"
    # Install AUR packages from shelly backup
    # Runs local script unless it does not exist (SCRIPT_DIR, not CWD)
    elif [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/configs/shelly-aur.toml" ]; then
      echo "Found local backup"
      shelly backup --import --name shelly-aur --directory "$SCRIPT_DIR/configs" --no-confirm || {
        rc=$?
        record_failure "Install AUR Packages (Shelly)" "shelly backup import exited with status $rc"
      }
    elif ! curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-aur.toml -o "$WORK_DIR/shelly-aur.toml"; then
      echo "--------------------------------------------------------------------"
      echo "Failed to download shelly backup. You can try running it manually:"
      echo "curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-aur.toml -o \"$WORK_DIR/shelly-aur.toml\""
      echo "--------------------------------------------------------------------"
      record_failure "Install AUR Packages (Shelly)" "failed to download shelly-aur.toml"
      echo "+ sleep 10" && sleep 10
    elif ! shelly backup --import --name shelly-aur --directory "$WORK_DIR" --no-confirm; then
      echo "--------------------------------------------------------------------"
      echo "Failed to install AUR packages. You can try running it manually:"
      echo "shelly backup --import --name shelly-aur --directory \"$WORK_DIR\" --no-confirm"
      echo "--------------------------------------------------------------------"
      record_failure "Install AUR Packages (Shelly)" "shelly backup import failed"
      echo "+ sleep 10" && sleep 10
    fi
    ;;
  "Install affinity with GUI")
    echo "Installing GUI dependencies"
    if command -v shelly >/dev/null; then
      echo "shelly found"
      shelly install standard python-pyqt6 --no-confirm ||
        record_failure "Install affinity with GUI" "installing python-pyqt6 via shelly failed"
    fi
    if command -v dnf >/dev/null; then
      echo "dnf found"
      sudo dnf install python3-pyqt6 ||
        record_failure "Install affinity with GUI" "installing python3-pyqt6 via dnf failed"
    fi
    if command -v apt >/dev/null; then
      echo "apt found"
      sudo apt install python3-pyqt6 -y ||
        record_failure "Install affinity with GUI" "installing python3-pyqt6 via apt failed"
    fi
    echo "Install affinity with ryzendew's gui installer"
    echo "You must manually select to install in the GUI"
    echo "Github repo: https://github.com/ryzendew/Linux-Affinity-Installer"
    echo "+ 10 sleep"
    sleep 10
    { curl -fsSL https://raw.githubusercontent.com/ryzendew/AffinityOnLinux/refs/heads/main/AffinityScripts/AffinityLinuxInstaller.py \
      -o "$WORK_DIR/AffinityLinuxInstaller.py" &&
      python3 "$WORK_DIR/AffinityLinuxInstaller.py"; } || {
      rc=$?
      record_failure "Install affinity with GUI" "affinity installer exited with status $rc"
    }
    ;;
  "Run bat setup script")
    echo "Running bat setup script..."
    # Runs local script unless it does not exist (SCRIPT_DIR, not CWD)
    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/bat.sh" ]; then
      echo "Found local script, running..."
      bash "$SCRIPT_DIR/bat.sh" --skip-watermark || {
        rc=$?
        record_failure "Run bat setup script" "bat.sh exited with status $rc"
      }
    else
      curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/bat.sh | bash -s -- --skip-watermark || {
        rc=$?
        record_failure "Run bat setup script" "downloaded bat.sh exited with status $rc"
      }
    fi
    ;;
  *)
    echo "Invalid option selected: $selection"
    ;;
  esac
done < <(printf '%s\n' "${OPTIONS[@]}")

echo "Installation process complete."

# Show (and save) what failed - the run itself never aborts on a failed step
if [ "${#FAILED[@]}" -gt 0 ]; then
  {
    echo ""
    echo "================ FAILURE SUMMARY ================"
    echo "installbeta.sh finished at $(date '+%F %T') - ${#FAILED[@]} step(s) failed:"
    printf '  - %s\n' "${FAILED[@]}"
    echo ""
    echo "Full console log: $LOG"
    echo "Failure report:   $REPORT"
    echo "==================================================="
  } | tee -a "$REPORT"

  if [ "$TTY_OK" = true ] && command -v gum >/dev/null; then
    gum_tty pager < "$REPORT" || true
  fi

  # Non-zero so callers and CI can detect the failed run
  exit 1
fi

echo "All steps completed with no failures."
exit 0
