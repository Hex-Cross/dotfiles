#!/bin/bash
STATE=$(eww active-windows 2>/dev/null)
if echo "$STATE" | grep -q "control_center"; then
    eww close control_center closer
else
    eww open-many closer control_center
fi

