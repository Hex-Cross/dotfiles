#!/bin/bash
# Outputs JSON array of nearby WiFi networks for eww
# Only rescan every 30s
SCAN_CACHE="/tmp/eww_wifi_scan"
if [ ! -f "$SCAN_CACHE" ] || [ $(($(date +%s) - $(stat -c %Y "$SCAN_CACHE"))) -gt 30 ]; then
    nmcli dev wifi rescan >/dev/null 2>&1 &
    touch "$SCAN_CACHE"
fi

RESULT=$(nmcli -t -f SIGNAL,SSID dev wifi list 2>/dev/null \
    | grep -v '^:' | grep -v ':--' \
    | sort -t: -k1 -rn \
    | awk -F: '!seen[$2]++ && $2!="" {
        # Escape special JSON characters
        gsub(/\\/, "\\\\", $2)
        gsub(/"/, "\\\"", $2)
        gsub(/\047/, "\\u0027", $2)
        printf "{\"ssid\":\"%s\",\"signal\":\"%s\"}\n", $2, $1
    }' | head -8)

if [ -z "$RESULT" ]; then
    echo '[]'
else
    echo "$RESULT" | paste -sd, | sed 's/^/[/;s/$/]/'
fi
