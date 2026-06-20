#!/usr/bin/env bash
set -euo pipefail

# Fixes nwg-displays not auto-updating monitor/workspace configs on hyprctl reload
# in Hyprland 0.55+ Lua-based configs.
#
# Problem: require() caches modules in package.loaded, so updated monitors.lua
# is ignored on config reload. Solution: clear the cache before require().
# See https://lua.org/manual/5.1/manual.html#pdf-require

HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
MAIN_LUA="$HYPR_DIR/hyprland.lua"

if [ ! -f "$MAIN_LUA" ]; then
    echo "Error: $MAIN_LUA not found. Is Hyprland 0.55+ configured with Lua?"
    exit 1
fi

# Create a backup (only if none exists)
if [ ! -f "$MAIN_LUA.bak" ]; then
    cp "$MAIN_LUA" "$MAIN_LUA.bak"
    echo "Backup saved: $MAIN_LUA.bak"
fi

patched=0

# Fix monitors
if grep -q 'require("monitors")' "$MAIN_LUA" && \
   ! grep -q 'package.loaded\["monitors"\]' "$MAIN_LUA"; then
    sed -i 's/^\s*--\s*require("monitors")/package.loaded["monitors"] = nil\nrequire("monitors")/' "$MAIN_LUA"
    echo "Patched: monitors.lua require() cache cleared"
    patched=1
else
    echo "Skipped monitors: already patched or not found"
fi

# Fix workspaces
if grep -q 'require("workspaces")' "$MAIN_LUA" && \
   ! grep -q 'package.loaded\["workspaces"\]' "$MAIN_LUA"; then
    sed -i 's/^\s*--\s*require("workspaces")/package.loaded["workspaces"] = nil\nrequire("workspaces")/' "$MAIN_LUA"
    echo "Patched: workspaces.lua require() cache cleared"
    patched=1
else
    echo "Skipped workspaces: already patched or not found"
fi

if [ "$patched" -eq 1 ]; then
    echo ""
    echo "Done! Run 'hyprctl reload' or restart Hyprland for the fix to take effect."
    echo "nwg-displays changes should now apply immediately."
else
    echo ""
    echo "No changes needed."
fi
