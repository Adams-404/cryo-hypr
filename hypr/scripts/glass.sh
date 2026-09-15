#!/usr/bin/env bash
# cryo-hypr Glassmorphism & Blur Configuration Engine

STATE_FILE="$HOME/.cache/glass_preset"
CURRENT_WALL=$(cat "$HOME/.cache/current_wallpaper" 2>/dev/null)

apply_preset() {
    local preset="$1"
    echo "$preset" > "$STATE_FILE"

    case "$preset" in
        liquid)
            # Liquid Glass: Clear, vibrant, high-refraction water-like acrylic
            hyprctl eval 'hl.config({ decoration = { blur = { enabled = true, size = 5, passes = 2, vibrancy = 0.45, noise = 0.012, contrast = 1.15, brightness = 1.00 } } })'
            GLASS_WOFI_OPACITY=0.48 GLASS_WAYBAR_OPACITY=0.60 python3 "$HOME/.config/hypr/scripts/extract_colors.py" "$CURRENT_WALL"
            notify-send "Glass Theme" "Liquid Glass activated (clear & vibrant)"
            ;;
        frosted)
            # Frosted Glass: Diffuse, milky, high-pass matte glass
            hyprctl eval 'hl.config({ decoration = { blur = { enabled = true, size = 9, passes = 3, vibrancy = 0.20, noise = 0.000, contrast = 0.95, brightness = 0.85 } } })'
            GLASS_WOFI_OPACITY=0.72 GLASS_WAYBAR_OPACITY=0.82 python3 "$HOME/.config/hypr/scripts/extract_colors.py" "$CURRENT_WALL"
            notify-send "Glass Theme" "Frosted Glass activated (diffuse matte)"
            ;;
        crystal)
            # Crystal: Ultra-light, clear transparency
            hyprctl eval 'hl.config({ decoration = { blur = { enabled = true, size = 3, passes = 1, vibrancy = 0.50, noise = 0.000, contrast = 1.20, brightness = 1.05 } } })'
            GLASS_WOFI_OPACITY=0.32 GLASS_WAYBAR_OPACITY=0.45 python3 "$HOME/.config/hypr/scripts/extract_colors.py" "$CURRENT_WALL"
            notify-send "Glass Theme" "Crystal Clear activated (ultra light)"
            ;;
        deep)
            # Deep Obsidian: Dark, high-contrast privacy glass
            hyprctl eval 'hl.config({ decoration = { blur = { enabled = true, size = 7, passes = 2, vibrancy = 0.30, noise = 0.020, contrast = 1.05, brightness = 0.70 } } })'
            GLASS_WOFI_OPACITY=0.85 GLASS_WAYBAR_OPACITY=0.90 python3 "$HOME/.config/hypr/scripts/extract_colors.py" "$CURRENT_WALL"
            notify-send "Glass Theme" "Deep Obsidian activated (rich dark glass)"
            ;;
        off)
            hyprctl eval 'hl.config({ decoration = { blur = { enabled = false } } })'
            GLASS_WOFI_OPACITY=0.92 GLASS_WAYBAR_OPACITY=0.92 python3 "$HOME/.config/hypr/scripts/extract_colors.py" "$CURRENT_WALL"
            notify-send "Glass Theme" "Blur disabled (solid opaque)"
            ;;
        *)
            echo "Usage: $0 [liquid|frosted|crystal|deep|off|menu]"
            exit 1
            ;;
    esac

    # Reload Waybar to apply new glass styling
    killall waybar 2>/dev/null
    sleep 0.3
    hyprctl dispatch 'hl.dsp.exec_cmd("waybar")' 2>/dev/null || waybar &
}

case "$1" in
    liquid|frosted|crystal|deep|off)
        apply_preset "$1"
        ;;
    menu|select|"")
        if pgrep -x "wofi" >/dev/null; then
            killall wofi
            exit 0
        fi
        OPTIONS="  Liquid Glass (Clear, Glossy & Vibrant)\n  Frosted Glass (Diffuse & Milky Matte)\n  Crystal Clear (Ultra-Light Translucency)\n  Deep Obsidian (Dark Tinted Glass)\n  Disable Blur"
        SELECTED=$(printf "%b" "$OPTIONS" | wofi --dmenu --prompt " Choose Glass Style..." --width 450 --height 300)
        case "$SELECTED" in
            *"Liquid"*)   apply_preset liquid ;;
            *"Frosted"*)  apply_preset frosted ;;
            *"Crystal"*)  apply_preset crystal ;;
            *"Obsidian"*) apply_preset deep ;;
            *"Disable"*)  apply_preset off ;;
        esac
        ;;
esac
