#!/bin/bash
# Universal battery ECO toggle — auto-detects ThinkPad, IdeaPad, or generic

BAT=$(ls /sys/class/power_supply/ | grep BAT | head -n 1)
[ -z "$BAT" ] && exit 0

# ThinkPad: charge thresholds
if [ -f "/sys/class/power_supply/$BAT/charge_control_end_threshold" ]; then
    STOP=$(cat /sys/class/power_supply/$BAT/charge_control_end_threshold 2>/dev/null || echo "100")
    if [ "$STOP" -lt 100 ]; then
        echo 100 | sudo tee /sys/class/power_supply/$BAT/charge_control_end_threshold > /dev/null
        echo 96 | sudo tee /sys/class/power_supply/$BAT/charge_control_start_threshold > /dev/null
    else
        echo 80 | sudo tee /sys/class/power_supply/$BAT/charge_control_end_threshold > /dev/null
        echo 75 | sudo tee /sys/class/power_supply/$BAT/charge_control_start_threshold > /dev/null
    fi

# IdeaPad: conservation_mode
elif [ -f "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode" ]; then
    ECO_FILE="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
    ECO=$(cat "$ECO_FILE" 2>/dev/null || echo "0")
    STATUS=$(cat /sys/class/power_supply/$BAT/status)
    LEVEL=$(cat /sys/class/power_supply/$BAT/capacity)

    # Block: charging below 100
    [ "$STATUS" = "Charging" ] && [ "$LEVEL" -lt 100 ] && exit 0
    # Block: critical
    [ "$STATUS" != "Charging" ] && [ "$STATUS" != "Full" ] && [ "$LEVEL" -le 20 ] && exit 0

    [ "$ECO" -eq 1 ] && printf "0" | sudo tee "$ECO_FILE" > /dev/null || printf "1" | sudo tee "$ECO_FILE" > /dev/null
fi

rm -f /tmp/ironbar_bat_state
