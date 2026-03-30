#!/bin/bash
SIGNAL=$(nmcli -t -f SIGNAL,ACTIVE dev wifi | grep 'yes' | cut -d: -f1)
if [ -z "$SIGNAL" ]; then SIGNAL=0; fi

# Create a visual 10-block bar
BAR_SIZE=10
FILLED=$((SIGNAL / 10))
EMPTY=$((BAR_SIZE - FILLED))

printf "%s " "$SIGNAL%"
for i in $(seq 1 $FILLED); do printf "█"; done
for i in $(seq 1 $EMPTY); do printf "░"; done
