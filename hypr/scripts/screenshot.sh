#!/usr/bin/env bash
# cryo-hypr Freeze-Frame Area Screenshot with toggle/cancel support

# 1. Toggle/cancel if already running
if pgrep -x "slurp" >/dev/null || pgrep -x "hyprpicker" >/dev/null; then
    killall slurp hyprpicker 2>/dev/null
    exit 0
fi

# Ensure hyprpicker is always cleaned up on exit
cleanup() {
    killall hyprpicker 2>/dev/null
}
trap cleanup EXIT

# 2. Freeze the screen in place so animations/videos pause
if command -v hyprpicker >/dev/null 2>&1; then
    hyprpicker -rz &
    sleep 0.18
fi

# 3. Select area with slurp
GEOM=$(slurp -b 00000044 -c ffffffaa -s 00000015 -w 1.5 2>/dev/null)

# 4. If an area was selected, capture and copy to clipboard
if [ -n "$GEOM" ]; then
    grim -g "$GEOM" - | wl-copy --type image/png
    cleanup
    notify-send -a "Cryo System" -i camera-photo -t 1800 "Screenshot Captured" "Area copied to clipboard"
fi
