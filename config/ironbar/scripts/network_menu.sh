#!/bin/bash

if pgrep -x "rofi" > /dev/null; then pkill -x "rofi"; exit 0; fi

# 1. Get System Stats for Sliders
VOL=$(pamixer --get-volume)
BRIGHT=$(brightnessctl -m | cut -d, -f4 | sed 's/%//')

# Function to create a text-based slider bar
make_bar() {
    local val=$1
    local filled=$((val / 10))
    local empty=$((10 - filled))
    local bar=""
    for i in $(seq 1 $filled); do bar+="█"; done
    for i in $(seq 1 $empty); do bar+="░"; done
    echo "$bar"
}

# 2. Build the Sections
VOL_BAR=$(make_bar $VOL)
BRI_BAR=$(make_bar $BRIGHT)

# Gather Connectivity
LAN=$(nmcli -t -f DEVICE,TYPE,STATE dev | grep "ethernet:connected" | awk -F: '{print "󰈀  LAN: Connected"}')
VPN=$(nmcli -t -f NAME,TYPE,STATE con show --active | grep "vpn" | awk -F: '{print "󰦝  VPN: " $1}')
BT_STATUS=$(bluetoothctl show | grep "Powered: yes" > /dev/null && echo "ON" || echo "OFF")

# Build the final list
options="󰕾  Volume: $VOL%  $VOL_BAR\n"
options+="󰃠  Bright: $BRIGHT% $BRI_BAR\n"
options+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
[ ! -z "$LAN" ] && options+="$LAN\n"
[ ! -z "$VPN" ] && options+="$VPN\n"
options+="󰂯  Bluetooth: $BT_STATUS\n"
options+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
options+=$(nmcli -t -f "SIGNAL,SSID" dev wifi list | sort -rn | uniq | awk -F: '{
    if ($2 != "" && $2 != "--") {
        if ($1 > 70) i="󰤨"; else if ($1 > 40) i="󰤥"; else i="󰤟";
        print i "  " $2
    }
}')

# 3. The "Pro MacBook" Theme String
chosen=$(echo -e "$options" | rofi -dmenu -i -p "Control Center" -no-config \
    -theme-str '
    * { 
        background-color: #1e1e2e; 
        text-color: #cdd6f4; 
        font: "JetBrainsMono Nerd Font 10";
    }
    window { 
        location: northeast; anchor: northeast; x-offset: -10px; y-offset: 55px;
        width: 320px; border: 2px; border-color: #1793d1; border-radius: 20px;
    }
    mainbox { padding: 15px; }
    inputbar { background-color: #313244; border-radius: 12px; padding: 10px; margin-bottom: 10px; children: [prompt, entry]; }
    prompt { text-color: #1793d1; }
    listview { lines: 12; fixed-height: false; scrollbar: false; spacing: 4px; }
    
    /* KILLING THE CREAM COLORS */
    element { padding: 10px; border-radius: 10px; background-color: #1e1e2e; }
    element normal.normal, element alternate.normal, element normal.active, element alternate.active {
        background-color: #1e1e2e;
    }
    element selected.normal { 
        background-color: #1793d1; 
        text-color: #ffffff; 
    }
    element-text { background-color: inherit; text-color: inherit; vertical-align: 0.5; }
    ')

# 4. Handle Clicks
if [ ! -z "$chosen" ]; then
    if [[ "$chosen" == 󰂯* ]]; then
        [[ "$BT_STATUS" == "ON" ]] && bluetoothctl power off || bluetoothctl power on
    elif [[ "$chosen" == 󰤨* ]] || [[ "$chosen" == 󰤥* ]] || [[ "$chosen" == 󰤟* ]]; then
        ssid=$(echo "$chosen" | sed 's/^..  //')
        nmcli dev wifi connect "$ssid"
    fi
fi
