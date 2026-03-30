#!/bin/bash

THEME="* {bg: #11111b; fg: #cdd6f4; sel: #1793d1; sf: #11111b; mb: #181825; br: #313244; font: \"JetBrainsMono Nerd Font 10\";}"
THEME="$THEME window {location: northeast; anchor: northeast; x-offset: -4px; y-offset: 34px; width: 180px; border: 2px solid; border-color: @br; border-radius: 16px; background-color: @bg;}"
THEME="$THEME mainbox {padding: 12px; background-color: transparent;}"
THEME="$THEME inputbar {enabled: false;}"
THEME="$THEME listview {lines: 5; fixed-height: false; scrollbar: false; spacing: 4px; background-color: transparent;}"
THEME="$THEME element {padding: 10px 15px; border-radius: 12px; background-color: @mb; text-color: @fg;}"
THEME="$THEME element normal.normal, element alternate.normal {background-color: @mb; text-color: @fg;}"
THEME="$THEME element selected.normal {background-color: @sel; text-color: @sf;}"
THEME="$THEME element-text {background-color: transparent; text-color: inherit;}"

CHOSEN=$(echo -e "Lock\nSleep\nLogout\nReboot\nShutdown" | rofi -dmenu -i -p "Power" -no-config -theme-str "$THEME")

case "$CHOSEN" in
    Lock)     loginctl lock-session ;;
    Sleep)    systemctl suspend ;;
    Logout)   hyprctl dispatch exit ;;
    Reboot)   systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
esac
