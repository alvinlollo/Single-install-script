#!/usr/bin/bash

# Strict mode from the very start: every tolerated failure in this script is
# an explicit guard (if ! / || record_failure), so preamble steps are checked
# too. Anything unguarded aborts the run via errexit.
set -euo pipefail

skip_watermark=false
if [ "${1:-}" = "--skip-watermark" ]; then
  skip_watermark=true
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
BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE UNDER THE GPL-2.0 LICENSE, 
THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. 
See the LICENSE for more detail
'
fi

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

# Run a long non-interactive step behind a spinner when gum exists, plain
# otherwise: the shelly bootstrap below must work on a system that has no gum
# yet. Routed through gum_tty so spinner escape codes stay out of $LOG.
run_step() {
  local title="$1" out rc=0
  shift
  if ! command -v gum >/dev/null; then
    "$@"
    return
  fi
  # gum spin --show-error would print the step's errors on gum's stderr, which
  # gum_tty sends to the terminal only. Capture the output here instead and
  # replay it on failure through stdout, so the cause also lands in $LOG.
  out="$(mktemp "$WORK_DIR/step-XXXXXX.out")"
  gum_tty spin -s dot --title "$title" -- bash -c '"$@" >"$0" 2>&1' "$out" "$@" || rc=$?
  if [ "$rc" -ne 0 ]; then
    cat "$out"
  fi
  rm -f "$out"
  return "$rc"
}

# Errors through gum log (level + colour + timestamp) once gum exists; plain
# echo before that, since the first record_failure can precede the bootstrap.
log_error() {
  if command -v gum >/dev/null; then
    gum log --level error --time kitchen -- "$*"
  else
    echo "!! $*"
  fi
}

# Same, for the failures that abort the run. `|| true` because gum exits 1
# on level fatal, which errexit would otherwise trip over mid-message.
log_fatal() {
  if command -v gum >/dev/null; then
    gum log --level fatal --time kitchen -- "$*" || true
  else
    echo "FATAL: $*"
  fi
}

# Record a failed step: remember it, print it now, keep installing
record_failure() {
  FAILED+=("$1 — $2")
  log_error "$1 — $2  (continuing with the rest of the installation)"
  # Plain line, no colour codes: this is what gum pager shows at the end
  echo "$(date '+%F %T')  $1 — $2" >>"$REPORT"
}

# Run a command; if it fails, print that exact command as a retry hint and
# record the failure. The hint is built from the arguments, so it cannot drift
# from what actually ran. Pass --spin TITLE first to run it via run_step.
# Usage: try_step STEP REASON MESSAGE [--spin TITLE] CMD...
try_step() {
  local step="$1" reason="$2" message="$3" title="" hint
  shift 3
  if [ "$1" = "--spin" ]; then
    title="$2"
    shift 2
  fi
  if [ -n "$title" ]; then
    run_step "$title" "$@" && return 0
  else
    "$@" && return 0
  fi
  printf -v hint '%q ' "$@"
  echo "--------------------------------------------------------------------"
  log_error "$message You can try running it manually:"
  echo "${hint% }"
  echo "--------------------------------------------------------------------"
  record_failure "$step" "$reason"
  return 1
}

# Installed-package count for the final summary. apt is deliberately not
# reported: on apt-only systems this prints nothing and no count line shows.
snapshot_pkg_count() {
  if command -v pacman >/dev/null; then
    pacman -Qq 2>/dev/null | wc -l
  elif command -v rpm >/dev/null; then
    rpm -qa --qf '%{NAME}\n' 2>/dev/null | wc -l
  fi
}

# Private temp workspace for downloads and clones. Predictable names in /tmp
# are a symlink attack vector on multi-user systems; the trap cleans up too.
WORK_DIR="$(mktemp -d)"

# Also stops the sudo keep-alive loop below when the script exits (any path:
# normal end, menu cancel, errexit, signal). SUDO_LOOP_PID is unset if the
# script bails out before the loop starts, hence the default value.
cleanup() {
  if [ -n "${SUDO_LOOP_PID:-}" ]; then
    # The loop's TERM trap also stops its current `sleep` (see below)
    kill "$SUDO_LOOP_PID" 2>/dev/null || true
  fi
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# Resolve where this script lives so local script/config fallbacks do not
# depend on the caller's current directory. Empty when piped (curl | bash).
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  SCRIPT_DIR=""
fi

# Ask for sudo upfront so the user is prompted only once. A cancelled prompt or
# a system without sudo aborts here with a clear message instead of an
# unexplained errexit exit later on.
if ! sudo -v; then
  log_fatal "sudo is required to run this installer (password prompt cancelled, or sudo is not available)."
  exit 1
fi

# Sudo keep-alive loop
sudo_keep_alive() {
  local sleep_pid=""
  # On TERM (from cleanup) stop the current sleep before exiting, otherwise it
  # lingers orphaned for up to 250s. Sleeping in the background and waiting
  # lets the trap fire immediately, and nothing else runs after it.
  trap 'kill "$sleep_pid" 2>/dev/null; exit' TERM
  while true; do
    sleep 250 &
    sleep_pid=$!
    wait "$sleep_pid"
    sudo -n true 2>/dev/null || true
    # $$ is the main script's PID even in this background subshell: exit as
    # soon as the installer is gone, as a backstop for the EXIT trap.
    kill -0 "$$" 2>/dev/null || exit
  done
}
# stderr silenced: no "Terminated" report from the loop's killed `sleep` may
# land in the tee'd log.
sudo_keep_alive 2>/dev/null &
SUDO_LOOP_PID=$!
echo "Keeping sudo alive on PID $SUDO_LOOP_PID - refreshing every 250s"

# Baseline for the package count in the final summary (empty on apt-only
# systems, where no count is reported). Taken before the first install step,
# which is the shelly bootstrap right below.
PKGS_BEFORE="$(snapshot_pkg_count)"

# Install shelly as a dependency if not present (Arch-based). This runs before
# any gum use on purpose: on a fresh Arch box gum comes from pacman here, so
# the bootstrap never depends on gum already being installed (and gum itself
# cannot be installed without shelly or apt).
if command -v pacman >/dev/null; then
  # Install build prerequisites for shelly. Plain command, not run_step: gum
  # may not exist yet at this point.
  try_step "Shelly bootstrap (Arch-only)" "failed to install base-devel/git prerequisites" \
    "Failed to install prerequisite packages for Shelly." \
    sudo pacman -S --needed --noconfirm base-devel git || true
  # gum from [extra], so the shelly build below gets a spinner and the rest of
  # the script has gum even if that build fails. Its own transaction and
  # non-fatal: a repo set without gum, or a stale sync db pointing at a removed
  # version, must not take base-devel/git down with it. No -Sy here (that
  # would be a partial upgrade); the safety net below retries via shelly.
  if ! command -v gum >/dev/null && ! sudo pacman -S --needed --noconfirm gum; then
    echo "Could not install gum with pacman - retrying via shelly after the bootstrap."
  fi
  # Check if shelly binary exists
  if ! command -v shelly >/dev/null; then
    echo "shelly is NOT installed. Running installation commands..."
    if try_step "Shelly bootstrap (Arch-only)" "failed to clone the shelly AUR repository" \
      "Failed to clone shelly repository." --spin "Clone Shelly from AUR" \
      git clone https://aur.archlinux.org/shelly.git "$WORK_DIR/shelly"; then
      try_step "Shelly bootstrap (Arch-only)" "failed to build shelly with makepkg" \
        "Failed to build and install shelly." --spin "Install Shelly" \
        makepkg -D "$WORK_DIR/shelly" -si --noconfirm || true
    fi
  else
    echo "Shelly is already installed."
  fi
fi

# Install prerequisites
if command -v shelly >/dev/null; then
  echo "Shelly detected. Installing prerequisites"
  # No gum here: pacman above provides it, the safety net below is the fallback
  shelly install standard base-devel git zsh curl wget libnewt rsync --upgrade --no-confirm ||
    record_failure "Prerequisites (shelly)" "installing base packages via shelly failed"
fi

if command -v apt >/dev/null; then
  echo "apt detected. Installing prerequisites"
  sudo apt update || record_failure "Prerequisites (apt)" "apt update failed"
  sudo apt full-upgrade -y || record_failure "Prerequisites (apt)" "apt full-upgrade failed"
  sudo -v
  sudo apt install git zsh curl wget rsync gum -y ||
    record_failure "Prerequisites (apt)" "apt install of base packages failed"
fi

# Ensure gum is installed (safety net: pacman/apt above should already have
# provided it, but nothing below can run without it)
if ! command -v gum >/dev/null; then
  echo "gum is not installed. Installing it now..."

  if command -v shelly >/dev/null; then
    echo "shelly detected. Installing gum"
    shelly install standard gum --no-confirm || {
      log_fatal "Failed to install gum. Exiting."
      exit 1
    }
  fi

  if command -v apt >/dev/null; then
    echo "apt detected. Installing gum"
    sudo apt install gum -y || {
      log_fatal "Failed to install gum. Exiting."
      exit 1
    }
  fi
fi

# gum drives every interactive dialog in this script and there is no fallback
# menu, so a system that ended up without it must abort here.
if ! command -v gum >/dev/null; then
  log_fatal "gum is required but could not be installed on this system (no shelly/apt found)."
  echo "Install it manually: https://github.com/charmbracelet/gum" >&2
  exit 1
fi

# Detect fish shell and warn user to run with bash instead (bash-only syntax).
# Placed after the gum bootstrap above so the dialog can always use gum confirm
# instead of falling back to a plain text prompt.
if [ -n "${FISH_VERSION:-}" ] || case "${SHELL:-}" in *fish*) ;; *) false ;; esac then
  if ! gum_tty confirm "$(printf 'Your default shell appears to be fish.\n\nThis script must be run with bash. It uses bash-only syntax and will fail under fish.\n\nRun it with:\n  bash installbeta.sh\n\nContinue anyway?')"; then
    log_fatal "Aborted. Please run this script with bash, not fish. e.g.: bash installbeta.sh"
    exit 1
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

# Present the menu with gum (gum is guaranteed by the bootstrap above)
if ! CHOICE=$(gum_tty choose --no-limit --height 14 \
  --header "Tab = select, Enter = confirm:" \
  --selected "Run fish setup script,Install Standard Packages (Shelly),Install AUR Packages (Shelly),Run bat setup script" \
  "${OPTIONS[@]}"); then
  echo "No options selected (menu cancelled). Nothing was installed."
  exit 1
fi

# gum exits 0 with empty output when nothing is selected - treat that as a
# cancel too, otherwise the run below would silently install nothing.
if [ -z "$CHOICE" ]; then
  echo "No options selected. Nothing was installed."
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
    sudo -v
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
    sudo -v
    # Runs local script unless it does not exist (SCRIPT_DIR, not CWD)
    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/fish.sh" ]; then
      echo "Found local script, running..."
      bash "$SCRIPT_DIR/fish.sh" --skip-watermark || {
        rc=$?
        record_failure "Run fish setup script" "fish.sh exited with status $rc"
      }
    else
      # Top-level pipe (like the zsh branch) so set -o pipefail catches a
      # failed download instead of reporting an empty script as success.
      curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/fish.sh | bash -s -- --skip-watermark || {
        rc=$?
        record_failure "Run fish setup script" "downloaded fish.sh exited with status $rc"
      }
    fi
    ;;
  "Run LazyVim setup script")
    echo "Running LazyVim setup script..."
    sudo -v
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
    sudo -v
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
    fi
    echo "NOTE: $USER has been added to the docker group."
    echo "Log out and back in (or reboot) for the group membership to take effect."
    ;;
  "Install Standard Packages (Shelly)")
    echo "Installing Standard Packages via Shelly backup..."
    sudo -v
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
    elif try_step "Install Standard Packages (Shelly)" "failed to download shelly-standard.toml" \
      "Failed to download shelly backup." \
      curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-standard.toml -o "$WORK_DIR/shelly-standard.toml"; then
      try_step "Install Standard Packages (Shelly)" "shelly backup import failed" \
        "Failed to install Standard packages." \
        shelly backup --import --name shelly-standard --directory "$WORK_DIR" --no-confirm || true
    fi
    ;;
  "Install AUR Packages (Shelly)")
    echo "Installing AUR Packages via Shelly backup..."
    sudo -v
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
    elif try_step "Install AUR Packages (Shelly)" "failed to download shelly-aur.toml" \
      "Failed to download shelly backup." \
      curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/shelly-aur.toml -o "$WORK_DIR/shelly-aur.toml"; then
      try_step "Install AUR Packages (Shelly)" "shelly backup import failed" \
        "Failed to install AUR packages." \
        shelly backup --import --name shelly-aur --directory "$WORK_DIR" --no-confirm || true
    fi
    ;;
  "Install affinity with GUI")
    echo "Installing GUI dependencies"
    sudo -v
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
    echo "Starting the GUI installer in 10 seconds - read the notes above first."
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
    log_error "Invalid option selected: $selection"
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
    gum_tty pager <"$REPORT" || true
  fi

  # Non-zero so callers and CI can detect the failed run
  exit 1
fi

echo "================ INSTALL SUMMARY ================"
echo "installbeta.sh finished at $(date '+%F %T') - no failures."
if [ -n "$PKGS_BEFORE" ]; then
  PKG_DELTA=$(($(snapshot_pkg_count) - PKGS_BEFORE))
  if [ "$PKG_DELTA" -gt 0 ]; then
    echo "Packages added: $PKG_DELTA"
  elif [ "$PKG_DELTA" -lt 0 ]; then
    echo "Packages removed: $((-PKG_DELTA))"
  else
    echo "Packages added: 0 (no net change)"
  fi
fi
echo ""
echo "Full console log: $LOG"
echo "Failure report:   $REPORT"
echo "==================================================="

exit 0
