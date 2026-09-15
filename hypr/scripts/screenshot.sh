#!/usr/bin/env bash
# cryo-hypr Area Screenshot with toggle/cancel support

if pgrep -x "slurp" >/dev/null; then
    killall slurp
    exit 0
fi

GEOM=$(slurp 2>/dev/null)
if [ -n "$GEOM" ]; then
    grim -g "$GEOM" - | wl-copy
    notify-send -t 1500 "Screenshot" "📸 Area copied to clipboard"
fi
