#!/usr/bin/env bash

# Kill existing instances if any to avoid duplicates
killall waybar 2>/dev/null
killall mako 2>/dev/null

# Start notification daemon
mako &

# Start status bar
waybar &

# Start wallpaper daemon if not running
if ! pgrep -x "awww-daemon" > /dev/null; then
    awww-daemon &
    sleep 0.8
fi

# Set wallpaper
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
DEFAULT_WALL="$WALLPAPER_DIR/glowing-rings-5120x2880-24778.png"

if [ -f "$DEFAULT_WALL" ]; then
    awww img "$DEFAULT_WALL" --transition-type wipe --transition-angle 30 --transition-step 90
elif [ -d "$WALLPAPER_DIR" ]; then
    FIRST_WALL=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | head -n 1)
    if [ -n "$FIRST_WALL" ]; then
        awww img "$FIRST_WALL" --transition-type wipe --transition-angle 30
    fi
fi
