#!/usr/bin/env bash
# cryo-hypr Glassmorphism & Blur Configuration Engine (Persistent)

CONFIG_DIR="$HOME/.config/hypr"
PRESET_FILE="$CONFIG_DIR/glass_preset"
GLASS_LUA="$CONFIG_DIR/glass.lua"
CURRENT_WALL=$(cat "$HOME/.cache/current_wallpaper" 2>/dev/null)
mkdir -p "$CONFIG_DIR"

apply_preset() {
    local preset="$1"
    echo "$preset" > "$PRESET_FILE"

    local blur_enabled="true"
    local blur_size="5"
    local blur_passes="2"
    local blur_vibrancy="0.45"
    local blur_noise="0.012"
    local blur_contrast="1.15"
    local blur_brightness="1.00"

    case "$preset" in
        liquid)
            # Liquid Glass: Clear, vibrant, high-refraction water-like acrylic
            blur_size="5"; blur_passes="2"; blur_vibrancy="0.45"; blur_noise="0.012"; blur_contrast="1.15"; blur_brightness="1.00"
            ;;
        frosted)
            # Frosted Glass: Diffuse, milky, high-pass matte glass
            blur_size="9"; blur_passes="3"; blur_vibrancy="0.20"; blur_noise="0.000"; blur_contrast="0.95"; blur_brightness="0.85"
            ;;
        crystal)
            # Crystal: Ultra-light, clear transparency
            blur_size="3"; blur_passes="1"; blur_vibrancy="0.50"; blur_noise="0.000"; blur_contrast="1.20"; blur_brightness="1.05"
            ;;
        deep)
            # Deep Obsidian: Dark, high-contrast privacy glass
            blur_size="7"; blur_passes="2"; blur_vibrancy="0.30"; blur_noise="0.020"; blur_contrast="1.05"; blur_brightness="0.70"
            ;;
        off)
            blur_enabled="false"
            ;;
        *)
            echo "Usage: $0 [liquid|frosted|crystal|deep|off|menu|restore]"
            exit 1
            ;;
    esac

    # 1. Write persistent glass.lua for Hyprland reload persistence
    cat <<EOF > "$GLASS_LUA"
-- cryo-hypr Persistent Glass Configuration ($preset)
hl.config({
    decoration = {
        blur = {
            enabled    = $blur_enabled,
            size       = $blur_size,
            passes     = $blur_passes,
            vibrancy   = $blur_vibrancy,
            noise      = $blur_noise,
            contrast   = $blur_contrast,
            brightness = $blur_brightness,
            popups     = true,
        },
    },
})
EOF

    # 2. Apply live to Hyprland
    hyprctl eval "hl.config({ decoration = { blur = { enabled = $blur_enabled, size = $blur_size, passes = $blur_passes, vibrancy = $blur_vibrancy, noise = $blur_noise, contrast = $blur_contrast, brightness = $blur_brightness, popups = true } } })" 2>/dev/null

    # 3. Regenerate colors.css with matching glass opacity
    python3 "$HOME/.config/hypr/scripts/extract_colors.py" "$CURRENT_WALL"

    # 4. Reload Waybar to apply new glass styling
    hyprctl dispatch 'hl.dsp.exec_cmd("~/.config/hypr/scripts/launch_waybar.sh")' 2>/dev/null || "$HOME/.config/hypr/scripts/launch_waybar.sh" &

    notify-send "Glass Theme" "Applied: $preset glass (saved & persistent)"
}

case "$1" in
    restore)
        PRESET="liquid"
        [ -f "$PRESET_FILE" ] && PRESET=$(cat "$PRESET_FILE")
        apply_preset "$PRESET"
        ;;
    liquid|frosted|crystal|deep|off)
        apply_preset "$1"
        ;;
    menu|select|"")
        if pgrep -x "wofi" >/dev/null; then
            killall wofi
            exit 0
        fi
        CURRENT="liquid"
        [ -f "$PRESET_FILE" ] && CURRENT=$(cat "$PRESET_FILE")
        OPTIONS="   Liquid Glass (Clear, Glossy and Vibrant)\n   Frosted Glass (Diffuse and Milky Matte)\n   Crystal Clear (Ultra-Light Translucency)\n   Deep Obsidian (Dark Tinted Glass)\n   Disable Blur"
        SELECTED=$(printf "%b" "$OPTIONS" | wofi --dmenu --prompt "Glass Style (Current: $CURRENT)..." --width 460 --height 300)
        case "$SELECTED" in
            *"Liquid"*)   apply_preset liquid ;;
            *"Frosted"*)  apply_preset frosted ;;
            *"Crystal"*)  apply_preset crystal ;;
            *"Obsidian"*) apply_preset deep ;;
            *"Disable"*)  apply_preset off ;;
        esac
        ;;
esac
