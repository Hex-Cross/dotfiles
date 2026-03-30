#!/bin/bash
FILE="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
CURRENT=$(cat $FILE)
if [ "$CURRENT" -eq 1 ]; then
    printf "0" | sudo tee $FILE
else
    printf "1" | sudo tee $FILE
fi
