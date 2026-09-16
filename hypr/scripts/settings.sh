#!/usr/bin/env bash
# cryo-hypr Unified Settings & Preferences Hub

# If wofi is already running, toggle it off
if pgrep -x "wofi" >/dev/null; then
    killall wofi
    exit 0
fi

case "$1" in
    glass|blur)
        exec "$HOME/.config/hypr/scripts/glass.sh" menu
        ;;
    color|theme)
        exec "$HOME/.config/hypr/scripts/theme_color.sh" menu
        ;;
    font|fontsize|scale)
        exec "$HOME/.config/hypr/scripts/fontsize.sh" menu
        ;;
    wifi|network)
        exec "$HOME/.config/hypr/scripts/wifi.sh"
        ;;
    wallpaper)
        exec "$HOME/.config/hypr/scripts/wallpaper.sh" select
        ;;
    audio|sound)
        exec pavucontrol &
        ;;
    *)
        OPTIONS="󰏘   Theme Accent Color (Manual Picker or Auto Wallpaper)\n   Glass and Blur Style (Liquid, Frosted, Crystal, Deep, Off)\n   Wallpaper Chooser (Live Preview)\n   Font and Text Size (Compact, Medium, Standard, Large)\n   Wi-Fi Wireless Networks\n   Network Connections Editor\n   Audio Mixer and Sound Devices\n   Keybindings and Documentation (README)"

        CHOSEN=$(printf "%b" "$OPTIONS" | wofi --dmenu --prompt "Settings & Preferences..." --width 480 --height 380)

        case "$CHOSEN" in
            *"Theme Accent Color"*)
                "$HOME/.config/hypr/scripts/theme_color.sh" menu &
                ;;
            *"Glass and Blur"*)
                "$HOME/.config/hypr/scripts/glass.sh" menu &
                ;;
            *"Wallpaper"*)
                "$HOME/.config/hypr/scripts/wallpaper.sh" select &
                ;;
            *"Font and Text"*)
                "$HOME/.config/hypr/scripts/fontsize.sh" menu &
                ;;
            *"Wi-Fi"*)
                "$HOME/.config/hypr/scripts/wifi.sh" &
                ;;
            *"Network Connections"*)
                nm-connection-editor &
                ;;
            *"Audio Mixer"*)
                pavucontrol &
                ;;
            *"Keybindings"*)
                xdg-open "$HOME/dotfiles/README.md" 2>/dev/null || xdg-open "https://github.com/Adams-404/cryo-hypr" &
                ;;
        esac
        ;;
esac
