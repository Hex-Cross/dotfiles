#!/bin/bash
BAT=$(ls /sys/class/power_supply | grep BAT | head -n 1)
STATUS=$(cat /sys/class/power_supply/$BAT/status)
LEVEL=$(cat /sys/class/power_supply/$BAT/capacity)

if [ "$STATUS" = "Charging" ]; then
    printf "charging"
elif [ "$LEVEL" -le 20 ]; then
    printf "critical"
else
    printf "arch-glow"
fi
