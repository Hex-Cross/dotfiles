#!/bin/bash

op=$(echo -e "  Shutdown\n󰜉  Restart\n󰤄  Sleep\n󰍃  Logout" | wofi --show dmenu --width=200 --height=250 --cache-file /dev/null)

case $op in
    "  Shutdown")
        systemctl poweroff
        ;;
    "󰜉  Restart")
        systemctl reboot
        ;;
    "󰤄  Sleep")
        systemctl suspend
        ;;
    "󰍃  Logout")
        hyprctl dispatch exit
        ;;
esac
