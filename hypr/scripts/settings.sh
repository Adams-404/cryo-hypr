#!/usr/bin/env bash
# cryo-hypr Unified Settings & Control Hub

# If wofi is already running, toggle it off
if pgrep -x "wofi" >/dev/null; then
    killall wofi
    exit 0
fi

case "$1" in
    gui|gnome|system)
        env XDG_CURRENT_DESKTOP=GNOME gnome-control-center &
        exit 0
        ;;
    glass|blur)
        exec "$HOME/.config/hypr/scripts/glass.sh" menu
        ;;
    font|fontsize|scale)
        exec "$HOME/.config/hypr/scripts/fontsize.sh" menu
        ;;
    wifi|network)
        exec "$HOME/.config/hypr/scripts/wifi.sh"
        ;;
    wallpaper|theme)
        exec "$HOME/.config/hypr/scripts/wallpaper.sh" select
        ;;
    audio|sound)
        exec pavucontrol &
        ;;
    *)
        OPTIONS="   All System Settings (GNOME Control Center)\n   Font and Text Scaling (Reduce / Increase)\n   Glass and Blur Style (Liquid, Frosted, Crystal, Deep)\n   Wallpaper and Colors (Live Preview Chooser)\n   Wi-Fi Wireless Networks\n   Network Connections Editor\n   Audio Mixer and Sound Devices\n   Displays and Screen Resolution\n   Bluetooth Devices\n   Power and Battery Management\n   Keyboard and Shortcuts\n   Keybindings and Documentation (README)"

        CHOSEN=$(printf "%b" "$OPTIONS" | wofi --dmenu --prompt "Settings & Preferences..." --width 480 --height 430)

        case "$CHOSEN" in
            *"All System Settings"*)
                env XDG_CURRENT_DESKTOP=GNOME gnome-control-center &
                ;;
            *"Font and Text"*)
                "$HOME/.config/hypr/scripts/fontsize.sh" menu &
                ;;
            *"Glass and Blur"*)
                "$HOME/.config/hypr/scripts/glass.sh" menu &
                ;;
            *"Wallpaper"*)
                "$HOME/.config/hypr/scripts/wallpaper.sh" select &
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
            *"Displays"*)
                env XDG_CURRENT_DESKTOP=GNOME gnome-control-center display &
                ;;
            *"Bluetooth"*)
                env XDG_CURRENT_DESKTOP=GNOME gnome-control-center bluetooth &
                ;;
            *"Power"*)
                env XDG_CURRENT_DESKTOP=GNOME gnome-control-center power &
                ;;
            *"Keyboard"*)
                env XDG_CURRENT_DESKTOP=GNOME gnome-control-center keyboard &
                ;;
            *"Keybindings"*)
                xdg-open "$HOME/dotfiles/README.md" 2>/dev/null || xdg-open "https://github.com/Adams-404/cryo-hypr" &
                ;;
        esac
        ;;
esac
