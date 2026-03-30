#!/bin/bash
BAT=$(ls /sys/class/power_supply | grep BAT | head -n 1)
LEVEL=$(cat /sys/class/power_supply/$BAT/capacity)
STATUS=$(cat /sys/class/power_supply/$BAT/status)

if [ "$STATUS" = "Charging" ]; then
    printf "${LEVEL}%% CHARGING"
elif [ "$LEVEL" -le 20 ]; then
    printf "${LEVEL}%% LOW"
else
    printf "${LEVEL}%%"
fi
