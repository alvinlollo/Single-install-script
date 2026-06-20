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

# Create a backup
cp "$MAIN_LUA" "$MAIN_LUA.bak"
echo "Backup saved: $MAIN_LUA.bak"

patched=0

# Fix monitors section
if grep -q '^if is_file_exists(HOME .. "/.config/hypr/monitors.lua") then' "$MAIN_LUA" && \
   ! grep -q 'package.loaded\["monitors"\]' "$MAIN_LUA"; then
    sed -i '/^if is_file_exists(HOME .. "\/.config\/hypr\/monitors.lua") then$/a\    package.loaded["monitors"] = nil' "$MAIN_LUA"
    echo "Patched: monitors.lua require() cache cleared"
    patched=1
else
    echo "Skipped monitors: already patched or not found"
fi

# Fix workspaces section
if grep -q '^if is_file_exists(HOME .. "/.config/hypr/workspaces.lua") then' "$MAIN_LUA" && \
   ! grep -q 'package.loaded\["workspaces"\]' "$MAIN_LUA"; then
    sed -i '/^if is_file_exists(HOME .. "\/.config\/hypr\/workspaces.lua") then$/a\    package.loaded["workspaces"] = nil' "$MAIN_LUA"
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
