#!/usr/bin/env bash
if pgrep -x "wofi" > /dev/null; then
    killall wofi
else
    wofi --show drun
fi
