#!/bin/bash
STATUS=$(bluetoothctl show | grep -q "Powered: yes" && echo "ON" || echo "OFF")
[ "$STATUS" = "ON" ] && bluetoothctl power off || bluetoothctl power on
