#!/usr/bin/env bash
# cryo-hypr Global Font Size & Scaling Engine

CACHE_FILE="$HOME/.cache/current_fontsize"
mkdir -p "$HOME/.cache"

# If wofi is already open, toggle it off
if [ "$1" = "menu" ] || [ -z "$1" ]; then
    if pgrep -x "wofi" >/dev/null; then
        killall wofi
        exit 0
    fi
fi

apply_fontsize() {
    local preset="$1"
    
    python3 - <<EOF
import os, re, subprocess

preset = "$preset"
cache_file = os.path.expanduser("~/.cache/current_fontsize")

# Read current factor if needed for inc/dec
curr_factor = 0.90
if os.path.exists(cache_file):
    try:
        with open(cache_file, "r") as f:
            val = f.read().strip()
            if val.replace('.', '', 1).isdigit():
                curr_factor = float(val)
    except Exception:
        pass

if preset == "compact":
    factor = 0.80
    wb_size = "10px"
    wofi_in = "11px"
    wofi_tx = "10px"
    rofi_sz = "9.5"
    mako_sz = "9"
    name = "Compact (80% / 9pt)"
elif preset == "medium":
    factor = 0.90
    wb_size = "11px"
    wofi_in = "12px"
    wofi_tx = "11px"
    rofi_sz = "10.5"
    mako_sz = "10"
    name = "Medium (90% / 10pt)"
elif preset == "large":
    factor = 1.15
    wb_size = "13px"
    wofi_in = "14px"
    wofi_tx = "13px"
    rofi_sz = "12.5"
    mako_sz = "12"
    name = "Large (115% / 12pt)"
elif preset == "inc":
    factor = min(1.40, round(curr_factor + 0.05, 2))
    name = f"Increased ({int(factor*100)}%)"
    wb_size = f"{int(12 * factor)}px"
    wofi_in = f"{int(13 * factor)}px"
    wofi_tx = f"{int(12 * factor)}px"
    rofi_sz = f"{11.5 * factor:.1f}"
    mako_sz = f"{int(11 * factor)}"
elif preset == "dec":
    factor = max(0.65, round(curr_factor - 0.05, 2))
    name = f"Decreased ({int(factor*100)}%)"
    wb_size = f"{int(12 * factor)}px"
    wofi_in = f"{int(13 * factor)}px"
    wofi_tx = f"{int(12 * factor)}px"
    rofi_sz = f"{11.5 * factor:.1f}"
    mako_sz = f"{int(11 * factor)}"
else: # default / normal
    factor = 1.00
    wb_size = "12px"
    wofi_in = "13px"
    wofi_tx = "12px"
    rofi_sz = "11.5"
    mako_sz = "11"
    name = "Standard (100% / 11pt)"


# 2. Save state
with open(cache_file, "w") as f:
    f.write(str(factor))

# 3. Update Waybar style.css root font-size
wb_css = os.path.expanduser("~/dotfiles/waybar/style.css")
if os.path.exists(wb_css):
    with open(wb_css, "r") as f:
        c = f.read()
    c = re.sub(r'(\*\s*\{[^}]*?font-size:\s*)\d+px;', rf'\g<1>{wb_size};', c)
    with open(wb_css, "w") as f:
        f.write(c)

# 4. Update Wofi style.css
wofi_css = os.path.expanduser("~/dotfiles/wofi/style.css")
if os.path.exists(wofi_css):
    with open(wofi_css, "r") as f:
        c = f.read()
    c = re.sub(r'(#input\s*\{[^}]*?font-size:\s*)\d+px;', rf'\g<1>{wofi_in};', c)
    c = re.sub(r'(#text\s*\{[^}]*?font-size:\s*)\d+px;', rf'\g<1>{wofi_tx};', c)
    with open(wofi_css, "w") as f:
        f.write(c)

# 5. Update Mako config
mako_conf = os.path.expanduser("~/dotfiles/mako/config")
if os.path.exists(mako_conf):
    with open(mako_conf, "r") as f:
        c = f.read()
    c = re.sub(r'font=JetBrains Mono \d+', f'font=JetBrains Mono {mako_sz}', c)
    with open(mako_conf, "w") as f:
        f.write(c)

# 6. Update Rofi config.rasi
rofi_conf = os.path.expanduser("~/dotfiles/rofi/config.rasi")
if os.path.exists(rofi_conf):
    with open(rofi_conf, "r") as f:
        c = f.read()
    c = re.sub(r'font:\s*"JetBrains Mono [^"]*";', f'font: "JetBrains Mono {rofi_sz}";', c)
    with open(rofi_conf, "w") as f:
        f.write(c)

print(name)
EOF

    # Reload daemons
    makoctl reload 2>/dev/null || true
    killall waybar 2>/dev/null
    sleep 0.2
    hyprctl dispatch 'hl.dsp.exec_cmd("waybar")' 2>/dev/null || waybar &
    notify-send "Font Size" "Applied: $preset scaling"
}

case "$1" in
    compact|small)
        apply_fontsize compact
        ;;
    medium)
        apply_fontsize medium
        ;;
    default|normal|standard)
        apply_fontsize default
        ;;
    large|big)
        apply_fontsize large
        ;;
    inc|increase|up)
        apply_fontsize inc
        ;;
    dec|decrease|down)
        apply_fontsize dec
        ;;
    menu|*)
        OPTIONS="  Compact (Small and Sharp - 80% / 9pt)\n  Medium (Sleek Modern - 90% / 10pt)\n  Standard (Default - 100% / 11pt)\n  Large (Comfortable - 115% / 12pt)\n  Increase Font Size (+5%)\n  Decrease Font Size (-5%)"
        CHOSEN=$(printf "%b" "$OPTIONS" | wofi --dmenu --prompt "Font Size and Scaling..." --width 460 --height 320)
        case "$CHOSEN" in
            *"Compact"*)  apply_fontsize compact ;;
            *"Medium"*)   apply_fontsize medium ;;
            *"Standard"*) apply_fontsize default ;;
            *"Large"*)    apply_fontsize large ;;
            *"Increase"*) apply_fontsize inc ;;
            *"Decrease"*) apply_fontsize dec ;;
        esac
        ;;
esac
