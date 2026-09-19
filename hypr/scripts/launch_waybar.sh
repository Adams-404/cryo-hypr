#!/usr/bin/env bash
# cryo-hypr Waybar Launcher with Hyprland 0.56+ Lua IPC compatibility shim

SHIM="$HOME/.config/waybar/hypr_compat.so"
[ ! -f "$SHIM" ] && SHIM="$HOME/cryo-hypr/waybar/hypr_compat.so"
[ ! -f "$SHIM" ] && SHIM="$HOME/dotfiles/waybar/hypr_compat.so"

killall waybar 2>/dev/null
sleep 0.2

if [ -f "$SHIM" ]; then
    exec env LD_PRELOAD="$SHIM" waybar
else
    exec waybar
fi
