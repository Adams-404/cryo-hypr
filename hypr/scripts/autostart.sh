#!/usr/bin/env bash

# Kill existing instances if any to avoid duplicates
killall waybar 2>/dev/null
killall mako 2>/dev/null

# Select wallpaper
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
DEFAULT_WALL="$WALLPAPER_DIR/glowing-rings-5120x2880-24778.png"

WALLPAPER=""
if [ -f "$DEFAULT_WALL" ]; then
    WALLPAPER="$DEFAULT_WALL"
elif [ -d "$WALLPAPER_DIR" ]; then
    WALLPAPER=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | head -n 1)
fi

# Extract dynamic palette from wallpaper
if [ -n "$WALLPAPER" ] && [ -f "$HOME/.config/hypr/scripts/extract_colors.py" ]; then
    python3 "$HOME/.config/hypr/scripts/extract_colors.py" "$WALLPAPER"
fi

# Start notification daemon
mako &

# Start status bar with dynamic theme
waybar &

# Start wallpaper daemon if not running
if ! pgrep -x "awww-daemon" > /dev/null; then
    awww-daemon &
    sleep 0.8
fi

# Set wallpaper
if [ -n "$WALLPAPER" ]; then
    awww img "$WALLPAPER" --transition-type wipe --transition-angle 30 --transition-step 90
fi
