#!/usr/bin/env bash
# cryo-hypr Theme Accent Color Selector

COLOR_FILE="$HOME/.config/hypr/theme_color"
CURRENT_WALL=$(cat "$HOME/.cache/current_wallpaper" 2>/dev/null)

apply_color() {
    local color="$1"
    if [ "$color" = "auto" ]; then
        rm -f "$COLOR_FILE"
        python3 "$HOME/.config/hypr/scripts/extract_colors.py" "$CURRENT_WALL"
        hyprctl dispatch 'hl.dsp.exec_cmd("~/.config/hypr/scripts/launch_waybar.sh")' 2>/dev/null || "$HOME/.config/hypr/scripts/launch_waybar.sh" &
        notify-send "Theme Color" "Restored to Auto (Wallpaper Sync)"
        exit 0
    fi

    # Clean hex code
    color=$(echo "$color" | grep -oE '#[0-9a-fA-F]{6}' | head -n 1)
    if [ -n "$color" ]; then
        echo "$color" > "$COLOR_FILE"
        python3 "$HOME/.config/hypr/scripts/extract_colors.py" "$CURRENT_WALL"
        hyprctl dispatch 'hl.dsp.exec_cmd("~/.config/hypr/scripts/launch_waybar.sh")' 2>/dev/null || "$HOME/.config/hypr/scripts/launch_waybar.sh" &
        notify-send "Theme Color" "Accent set to $color"
    fi
}

case "$1" in
    auto)
        apply_color auto
        ;;
    \#*)
        apply_color "$1"
        ;;
    menu|*)
        if pgrep -x "wofi" >/dev/null; then
            killall wofi
            exit 0
        fi

        CURRENT="Auto"
        [ -f "$COLOR_FILE" ] && CURRENT=$(cat "$COLOR_FILE")

        OPTIONS="   Auto (Follow Wallpaper Palette)\n   Sapphire Blue (#388bfd)\n   Cyber Violet (#a371f7)\n   Sakura Pink (#f778ba)\n   Crimson Flame (#f75555)\n   Sunset Orange (#f78412)\n   Amber Gold (#f0b72f)\n   Emerald Green (#2ea043)\n   Ocean Cyan (#2dd4bf)\n   Monochrome Ice (#e6edf3)\n󰏘   Custom Hex Code (Type in search box e.g. #ff007f)"

        CHOSEN=$(printf "%b" "$OPTIONS" | wofi --dmenu --prompt "Theme Color (Current: $CURRENT)..." --width 480 --height 430)

        case "$CHOSEN" in
            *"Auto"*)
                apply_color auto
                ;;
            *"#"*)
                apply_color "$CHOSEN"
                ;;
        esac
        ;;
esac
