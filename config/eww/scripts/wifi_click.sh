#!/bin/bash
# Usage: wifi_click.sh <action> [ssid]
# action: connect | edit | edit_current

ACTION="$1"
SSID="$2"

case "$ACTION" in
    connect)
        nmcli dev wifi connect "$SSID" 2>&1
        ;;
    edit)
        UUID=$(nmcli -t -f NAME,UUID con show | grep "^${SSID}:" | cut -d: -f2 | head -1)
        if [ -n "$UUID" ]; then
            nm-connection-editor --edit="$UUID" &
        else
            nm-connection-editor &
        fi
        ;;
    edit_current)
        CURRENT=$(nmcli -t -f NAME,TYPE con show --active | grep wireless | cut -d: -f1 | head -1)
        UUID=$(nmcli -t -f NAME,UUID con show | grep "^${CURRENT}:" | cut -d: -f2 | head -1)
        if [ -n "$UUID" ]; then
            nm-connection-editor --edit="$UUID" &
        else
            nm-connection-editor &
        fi
        ;;
esac
