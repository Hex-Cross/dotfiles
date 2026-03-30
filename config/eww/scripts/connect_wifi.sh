#!/bin/bash
# Connects to a WiFi network by SSID
# Usage: connect_wifi.sh <ssid>
SSID="$1"
nmcli dev wifi connect "$SSID" 2>&1
