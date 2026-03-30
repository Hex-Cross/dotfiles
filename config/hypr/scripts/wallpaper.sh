#!/bin/bash
killall hyprpaper 2>/dev/null
sleep 0.5
hyprpaper &
sleep 2
MONITOR=$(hyprctl monitors | grep "Monitor" | head -1 | awk '{print $2}')
WALLPAPER=$(ls ~/Pictures/Wallpapers/ | grep "\-dim" | head -1)
[ -z "$WALLPAPER" ] && WALLPAPER=$(ls ~/Pictures/Wallpapers/ | head -1)
hyprctl hyprpaper preload ~/Pictures/Wallpapers/$WALLPAPER
hyprctl hyprpaper wallpaper $MONITOR,~/Pictures/Wallpapers/$WALLPAPER
