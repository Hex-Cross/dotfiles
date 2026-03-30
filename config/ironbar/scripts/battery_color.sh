#!/bin/bash
STATUS=$(cat /sys/class/power_supply/BAT0/status)
if [ "$STATUS" = "Charging" ]; then
    echo "charging"
else
    echo "normal"
fi
