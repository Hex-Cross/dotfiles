#!/bin/bash
if nmcli connection show --active | grep -q "Simedia"; then
    # VPN ON: Glowing Alien (󰚩) 
    echo '{"text": "󰚩", "class": "connected"}' 
else
    # VPN OFF: Pirate Ship (󰙨) 
    echo '{"text": "󰙨", "class": "disconnected"}'
fi
