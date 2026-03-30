#!/bin/bash
VPN_NAME=$(nmcli -t -f NAME,TYPE con show | grep wireguard | cut -d: -f1 | head -1)
[ -z "$VPN_NAME" ] && exit 1
STATUS=$(nmcli -t -f NAME,TYPE con show --active | grep -q wireguard && echo "ON" || echo "OFF")
[ "$STATUS" = "ON" ] && nmcli con down "$VPN_NAME" || nmcli con up "$VPN_NAME"
