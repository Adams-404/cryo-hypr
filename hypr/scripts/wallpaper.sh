#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
STATE_FILE="$HOME/.cache/current_wallpaper"
mkdir -p "$HOME/.cache"

if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send "Wallpapers" "No wallpaper directory found at $WALLPAPER_DIR"
    exit 1
fi

set_wallpaper() {
    local wall="$1"
    if [ -f "$wall" ]; then
        echo "$wall" > "$STATE_FILE"
        # Extract dynamic colors
        python3 "$HOME/.config/hypr/scripts/extract_colors.py" "$wall"
        # Set wallpaper with animated wipe
        awww img "$wall" --transition-type wipe --transition-angle 30 --transition-step 90
        # Reload Waybar with new colors
        hyprctl dispatch 'hl.dsp.exec_cmd("~/.config/hypr/scripts/launch_waybar.sh")' 2>/dev/null || "$HOME/.config/hypr/scripts/launch_waybar.sh" &
        notify-send "Wallpaper Updated" "$(basename "$wall")"
    fi
}

case "$1" in
    next|random)
        CURRENT=$(cat "$STATE_FILE" 2>/dev/null)
        WALL=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | grep -vF "$CURRENT" | shuf -n 1)
        [ -z "$WALL" ] && WALL=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | head -n 1)
        set_wallpaper "$WALL"
        ;;
    select|choose)
        # Toggle: If picker is already running, close it
        if pgrep -f "wallpaper_picker.py" >/dev/null; then
            killall -f "wallpaper_picker.py" 2>/dev/null
            exit 0
        fi
        python3 "$HOME/.config/hypr/scripts/wallpaper_picker.py"
        ;;
    *)
        "$0" next
        ;;
esac
