#!/bin/bash
# Bluetooth device manager via rofi
# Shows paired devices, option to forget or connect/disconnect

DEVICES=$(bluetoothctl devices Paired 2>/dev/null | sed 's/^Device //')

[ -z "$DEVICES" ] && exit 0

# Build menu: "MAC Name"
CHOSEN=$(echo "$DEVICES" | awk '{mac=$1; $1=""; name=substr($0,2); print name " (" mac ")"}' \
    | rofi -dmenu -i -p "Bluetooth Devices" -no-config \
    -theme-str '
    * { background-color: #1e1e2e; text-color: #cdd6f4; font: "JetBrainsMono Nerd Font 10"; }
    window { location: northeast; anchor: northeast; x-offset: -10px; y-offset: 55px; width: 300px; border: 2px; border-color: #1793d1; border-radius: 20px; }
    mainbox { padding: 15px; }
    inputbar { background-color: #313244; border-radius: 12px; padding: 10px; margin-bottom: 10px; children: [prompt, entry]; }
    prompt { text-color: #1793d1; }
    listview { lines: 8; fixed-height: false; scrollbar: false; spacing: 4px; }
    element { padding: 10px; border-radius: 10px; background-color: #1e1e2e; }
    element normal.normal, element alternate.normal { background-color: #1e1e2e; }
    element selected.normal { background-color: #1793d1; text-color: #ffffff; }
    element-text { background-color: inherit; text-color: inherit; }
    ')

[ -z "$CHOSEN" ] && exit 0

# Extract MAC from selection
MAC=$(echo "$CHOSEN" | grep -oP '\(.*?\)' | tr -d '()')
DEVNAME=$(echo "$CHOSEN" | sed 's/ (.*)//')

# Ask action
ACTION=$(echo -e "Connect\nDisconnect\nForget" | rofi -dmenu -i -p "$DEVNAME" -no-config \
    -theme-str '
    * { background-color: #1e1e2e; text-color: #cdd6f4; font: "JetBrainsMono Nerd Font 10"; }
    window { location: northeast; anchor: northeast; x-offset: -10px; y-offset: 55px; width: 200px; border: 2px; border-color: #1793d1; border-radius: 20px; }
    mainbox { padding: 15px; }
    inputbar { enabled: false; }
    listview { lines: 3; fixed-height: false; scrollbar: false; spacing: 4px; }
    element { padding: 10px; border-radius: 10px; background-color: #1e1e2e; }
    element normal.normal, element alternate.normal { background-color: #1e1e2e; }
    element selected.normal { background-color: #1793d1; text-color: #ffffff; }
    element-text { background-color: inherit; text-color: inherit; }
    ')

case "$ACTION" in
    Connect)    bluetoothctl connect "$MAC" ;;
    Disconnect) bluetoothctl disconnect "$MAC" ;;
    Forget)     bluetoothctl remove "$MAC" ;;
esac

