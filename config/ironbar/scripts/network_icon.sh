#!/bin/bash
# Shows WiFi signal bars like macOS menu bar

SIGNAL=$(nmcli -t -f SIGNAL,ACTIVE dev wifi 2>/dev/null | grep yes | cut -d: -f1)

if [ -n "$SIGNAL" ] && [ "$SIGNAL" -gt 0 ] 2>/dev/null; then
    if   [ "$SIGNAL" -ge 80 ]; then printf "󰤨 ▂▄▆█"
    elif [ "$SIGNAL" -ge 60 ]; then printf "󰤥 ▂▄▆░"
    elif [ "$SIGNAL" -ge 40 ]; then printf "󰤢 ▂▄░░"
    elif [ "$SIGNAL" -ge 20 ]; then printf "󰤟 ▂░░░"
    else printf "󰤯 ░░░░"
    fi
elif nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -q "ethernet:connected"; then
    printf "󰈀 LAN"
else
    printf "󰤭 OFF"
fi
