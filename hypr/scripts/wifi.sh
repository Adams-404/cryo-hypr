#!/usr/bin/env bash
# cryo-hypr Wi-Fi Selector & Network Manager

# If wofi is already running, toggle it off
if pgrep -x "wofi" >/dev/null; then
    killall wofi
    exit 0
fi

# Check if Wi-Fi is enabled
WIFI_STATUS=$(nmcli -fields WIFI g 2>/dev/null | tail -n 1 | tr -d ' ')

if [ "$WIFI_STATUS" = "disabled" ]; then
    CHOICE=$(printf "󰖩  Turn Wi-Fi ON\n  Open Network Connections" | wofi --dmenu --prompt "Wi-Fi is Off" --width 380 --height 200)
    case "$CHOICE" in
        *"Turn Wi-Fi ON"*)
            nmcli r wifi on
            notify-send "Wi-Fi" "Wi-Fi turned ON"
            ;;
        *"Network Connections"*)
            nm-connection-editor &
            ;;
    esac
    exit 0
fi

# Get active SSID
ACTIVE_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes:' | cut -d: -f2)

# Build list of available networks using colon-separated nmcli output
NETWORKS=$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null | while IFS=: read -r in_use ssid signal sec; do
    [ -z "$ssid" ] && continue
    if [ "$in_use" = "*" ]; then
        echo "  $ssid (Connected) [${signal}%]"
    else
        icon=""
        [[ "$sec" =~ WPA|WEP|802\.1X ]] && icon=""
        echo "$icon  $ssid [${signal}%]"
    fi
done | awk '!seen[$0]++')

MENU_HEADER="󰖪  Turn Wi-Fi OFF\n  Open Network Connections\n  Rescan Networks\n---"
FULL_MENU=$(printf "%b\n%s" "$MENU_HEADER" "$NETWORKS")

CHOSEN=$(echo "$FULL_MENU" | wofi --dmenu --prompt "  Select Network..." --width 450 --height 380)

[ -z "$CHOSEN" ] && exit 0

case "$CHOSEN" in
    *"Turn Wi-Fi OFF"*)
        nmcli r wifi off
        notify-send "Wi-Fi" "Wi-Fi turned OFF"
        ;;
    *"Open Network Connections"*)
        nm-connection-editor &
        ;;
    *"Rescan Networks"*)
        nmcli dev wifi rescan 2>/dev/null
        sleep 0.8
        exec "$0"
        ;;
    *"---"*)
        exit 0
        ;;
    *)
        # Extract exact SSID from selection
        CLEAN_SSID=$(echo "$CHOSEN" | sed -E 's/^[][[:space:]]+//; s/[[:space:]]+\(Connected\)//; s/[[:space:]]+\[[0-9]+%\]$//')
        
        if [ "$CLEAN_SSID" = "$ACTIVE_SSID" ]; then
            ACTION=$(printf "Disconnect from %s\nForget %s\nCancel" "$CLEAN_SSID" "$CLEAN_SSID" | wofi --dmenu --prompt "$CLEAN_SSID" --width 360 --height 200)
            case "$ACTION" in
                *"Disconnect"*)
                    nmcli con down id "$CLEAN_SSID" 2>/dev/null || nmcli dev disconnect wlan0
                    notify-send "Wi-Fi" "Disconnected from $CLEAN_SSID"
                    ;;
                *"Forget"*)
                    nmcli con delete id "$CLEAN_SSID"
                    notify-send "Wi-Fi" "Connection $CLEAN_SSID removed"
                    ;;
            esac
            exit 0
        fi

        # Check if network is already known/saved
        KNOWN=$(nmcli -t -f NAME connection show | grep -xF "$CLEAN_SSID")
        
        if [ -n "$KNOWN" ]; then
            notify-send "Wi-Fi" "Connecting to $CLEAN_SSID..."
            if nmcli connection up id "$CLEAN_SSID"; then
                notify-send "Wi-Fi" "Connected to $CLEAN_SSID"
            else
                notify-send "Wi-Fi" "Failed to connect to $CLEAN_SSID"
            fi
        else
            # Check security type
            IS_SECURE=$(echo "$CHOSEN" | grep -E '^')
            if [ -n "$IS_SECURE" ]; then
                PASS=$(wofi --dmenu --password --prompt "Enter password for $CLEAN_SSID:" --width 400 --height 180)
                [ -z "$PASS" ] && exit 0
                notify-send "Wi-Fi" "Connecting to $CLEAN_SSID..."
                if nmcli dev wifi connect "$CLEAN_SSID" password "$PASS"; then
                    notify-send "Wi-Fi" "Successfully connected to $CLEAN_SSID"
                else
                    notify-send "Wi-Fi" "Connection failed. Please check password."
                fi
            else
                notify-send "Wi-Fi" "Connecting to $CLEAN_SSID..."
                nmcli dev wifi connect "$CLEAN_SSID"
            fi
        fi
        ;;
esac
