#!/bin/bash
FILE="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
PERCENT=$(cat /sys/class/power_supply/BAT0/capacity)
STATUS=$(cat /sys/class/power_supply/BAT0/status)

# 1. Toggle Logic
if [[ "$1" == "toggle" ]]; then
    CURRENT=$(cat "$FILE")
    [ "$CURRENT" -eq 1 ] && echo 0 | sudo tee "$FILE" || echo 1 | sudo tee "$FILE"
fi

# 2. Status Logic
MODE=$(cat "$FILE")
CLASS="normal"

# 1st Priority: Is the battery actually dying? (Critical)
if [ "$PERCENT" -le 20 ] && [[ "$STATUS" != "Charging" ]]; then
    COLOR="rgba(243, 139, 168, 1)" # Red
    TEXT="$PERCENT% (CRITICAL)"
    CLASS="critical"
# 2nd Priority: Are we manually limiting the charge? (Eco)
elif [ "$MODE" -eq 1 ]; then
    COLOR="rgba(23, 147, 209, 0.4)" # Dim Blue
    TEXT="$PERCENT% (Eco)"
    CLASS="eco"
# 3rd Priority: Are we plugged in? (Charging)
elif [[ "$STATUS" == "Charging" || "$STATUS" == "Full" || "$STATUS" == "Not charging" ]]; then
    COLOR="rgba(166, 227, 161, 1)" # Bright Green
    TEXT="$PERCENT% (CHARGING)"
    CLASS="charging"
# Default state
else
    COLOR="rgba(23, 147, 209, 1)" # Standard Blue
    TEXT="$PERCENT%"
fi

# 3. Final Output (Sends text, the water-level style, and the class)
STYLE="background: linear-gradient(90deg, $COLOR $PERCENT%, rgba(0,0,0,0) $PERCENT%) !important;"
printf '{"text": "%s", "style": "%s", "class": "%s"}\n' "$TEXT" "$STYLE" "$CLASS"
