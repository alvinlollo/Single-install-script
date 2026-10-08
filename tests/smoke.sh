#!/usr/bin/env bash
# Manual end-to-end smoke test. NOT part of the pre-push hook - run by hand:
#
#   tests/smoke.sh                 # default set: bat.sh zsh.sh fish.sh
#   tests/smoke.sh LazyVim.sh      # opt in to the heavy LazyVim run
#   tests/smoke.sh bat.sh          # run specific scripts only
#
# Runs each script inside a throwaway Arch container with a stubbed 'sudo'
# (the container is already root). Needs docker or podman and network access.
# This is what catches the bug class shellcheck cannot: inverted conditions,
# swapped shell branches, quoting that collapses when written to a file.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v docker >/dev/null 2>&1; then
  RUNTIME=docker
elif command -v podman >/dev/null 2>&1; then
  RUNTIME=podman
else
  echo "error: neither docker nor podman found - cannot run the smoke test." >&2
  exit 1
fi

DEFAULT_SCRIPTS=(bat.sh zsh.sh fish.sh)
if [ "$#" -gt 0 ]; then
  SCRIPTS=("$@")
else
  SCRIPTS=("${DEFAULT_SCRIPTS[@]}")
fi

# Validate arguments up front so a typo does not run in a container first
for s in "${SCRIPTS[@]}"; do
  if [ ! -f "$ROOT/$s" ]; then
    echo "error: $s not found in $ROOT" >&2
    exit 1
  fi
done

# Everything inside the container:
#  - copy the read-only mount so scripts that write to their own directory
#    (fish.sh syncing configs/) cannot mutate the host checkout
#  - stub 'sudo' -> exec (container already runs as root)
#  - pacman -Sy so package lookups work on a fresh image
#  - HOME=/root keeps every script writing inside the container
container_run() {
  local body="$1"
  "$RUNTIME" run --rm \
    -v "$ROOT:/src:ro" \
    -e HOME=/root \
    archlinux:latest \
    bash -c "
set -euo pipefail
cp -r /src /work
cd /work
printf '#!/bin/sh\nexec \"\$@\"\n' > /usr/local/bin/sudo
chmod +x /usr/local/bin/sudo
pacman -Sy --noconfirm >/dev/null 2>&1 || true
$body
"
}

declare -a RESULTS=()
overall=0

run_test() {
  local script="$1" body="$2"
  echo ""
  echo "=== smoke: $script ==="
  if container_run "$body"; then
    echo "=== PASS: $script ==="
    RESULTS+=("PASS  $script")
  else
    echo "=== FAIL: $script (exit $?)" >&2
    RESULTS+=("FAIL  $script")
    overall=1
  fi
}

for script in "${SCRIPTS[@]}"; do
  case "$script" in
  bat.sh)
    run_test "$script" '
      bash bat.sh --skip-watermark
      command -v bat >/dev/null || { echo "bat not on PATH after install"; exit 1; }
      grep -qxF -- "--theme=\"Catppuccin Mocha\"" "$(bat --config-dir)/config" \
        || { echo "theme line missing from bat config:"; cat "$(bat --config-dir)/config" 2>/dev/null; exit 1; }
      [ -s "$(bat --config-dir)/themes/Catppuccin Mocha.tmTheme" ] \
        || { echo "theme file was not downloaded"; exit 1; }
      # re-run must be idempotent (no duplicate config lines)
      bash bat.sh --skip-watermark
      [ "$(grep -cF -- "--theme=" "$(bat --config-dir)/config")" -eq 1 ] \
        || { echo "bat config is not idempotent"; exit 1; }
    '
    ;;
  zsh.sh)
    run_test "$script" '
      # pre-seed a config so BOTH runs have something to back up
      printf "# preexisting zshrc marker\n" > /root/.zshrc
      bash zsh.sh --skip-watermark
      [ -f /root/.zshrc ] || { echo ".zshrc missing"; exit 1; }
      [ -d /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions ] || { echo "plugins missing"; exit 1; }
      n=$(find /root -maxdepth 1 -name ".zshrc.bak-*" | wc -l)
      [ "$n" -eq 1 ] || { echo "expected 1 backup after first run, got $n"; exit 1; }
      grep -q "preexisting zshrc marker" /root/.zshrc.bak-* \
        || { echo "first backup does not hold the original config"; exit 1; }
      # second run must rotate (new timestamped backup), not overwrite
      bash zsh.sh --skip-watermark
      n=$(find /root -maxdepth 1 -name ".zshrc.bak-*" | wc -l)
      [ "$n" -eq 2 ] || { echo "expected 2 backups after second run (rotation), got $n"; exit 1; }
      grep -q "preexisting zshrc marker" /root/.zshrc.bak-* \
        || { echo "second run destroyed an earlier backup"; exit 1; }
    '
    ;;
  fish.sh)
    run_test "$script" '
      export SKIP_END4_SETUP=1
      bash fish.sh --skip-watermark
      [ -f /root/.config/fish/config.fish ] || { echo "fish config not installed"; exit 1; }
      fish -c "type -q fisher" || { echo "fisher not installed in fish"; exit 1; }
      # the fixed prerequisite check must have installed fish itself
      command -v fish >/dev/null || { echo "fish missing"; exit 1; }
    '
    ;;
  LazyVim.sh)
    run_test "$script" '
      bash LazyVim.sh
      [ -d /root/.config/nvim ] || { echo "nvim config not cloned"; exit 1; }
      command -v node >/dev/null || { echo "no node after install"; exit 1; }
      # timestamped backup only if a config existed; none here, so just assert
      # the clone exists and nothing is named plain nvim.bak
      [ ! -e /root/.config/nvim.bak ] || { echo "legacy .bak name used"; exit 1; }
    '
    ;;
  *)
    echo "error: unknown smoke test '$script' (known: bat.sh zsh.sh fish.sh LazyVim.sh)" >&2
    exit 1
    ;;
  esac
done

echo ""
echo "=== smoke summary ==="
printf '%s\n' "${RESULTS[@]}"
exit "$overall"
