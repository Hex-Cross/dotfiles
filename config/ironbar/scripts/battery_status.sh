#!/bin/bash
BAT=$(ls /sys/class/power_supply/ | grep BAT | head -n 1)
[ -z "$BAT" ] && { echo "No Battery"; exit 0; }
STATUS=$(cat /sys/class/power_supply/$BAT/status)
LEVEL=$(cat /sys/class/power_supply/$BAT/capacity)
STATE_FILE="/tmp/ironbar_bat_state"
WIDGET="battery"
ALL_CLASSES="charging full-eco eco critical normal"
ECO=0
if [ -f "/sys/class/power_supply/$BAT/charge_control_end_threshold" ]; then
    STOP=$(cat /sys/class/power_supply/$BAT/charge_control_end_threshold 2>/dev/null || echo "100")
    [ "$STOP" -lt 100 ] && ECO=1
elif [ -f "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode" ]; then
    ECO=$(cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode 2>/dev/null || echo "0")
fi
if [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ] || [ "$STATUS" = "Not charging" ]; then
    if [ "$ECO" -eq 1 ]; then STATE="full-eco"
    elif [ "$LEVEL" -ge 100 ]; then STATE="full-eco"
    else STATE="charging"; fi
elif [ "$LEVEL" -le 20 ]; then STATE="critical"
elif [ "$ECO" -eq 1 ]; then STATE="eco"
else STATE="normal"; fi
LAST_STATE=$(cat "$STATE_FILE" 2>/dev/null)
if [ "$STATE" != "$LAST_STATE" ]; then
    echo "$STATE" > "$STATE_FILE"
    { for c in $ALL_CLASSES; do ironbar style remove-class "$WIDGET" "$c"; done
      ironbar style add-class "$WIDGET" "$STATE"; } &>/dev/null
fi
if [ "$STATUS" = "Charging" ]; then
    [ "$ECO" -eq 1 ] && printf "%s%% ECO" "$LEVEL" || printf "%s%% CHARGING" "$LEVEL"
elif [ "$STATUS" = "Not charging" ] && [ "$ECO" -eq 1 ]; then printf "%s%% ECO" "$LEVEL"
elif [ "$STATUS" = "Full" ]; then printf "%s%% FULL" "$LEVEL"
elif [ "$LEVEL" -le 20 ]; then printf "%s%% LOW" "$LEVEL"
elif [ "$ECO" -eq 1 ]; then printf "%s%% ECO" "$LEVEL"
else printf "%s%%" "$LEVEL"; fi
