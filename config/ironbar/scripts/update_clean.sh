#!/bin/bash

CACHE_DIR="/tmp/ironbar_cache"
mkdir -p "$CACHE_DIR"

OFFICIAL=$(cat "$CACHE_DIR/official" 2>/dev/null || echo "0")
AUR=$(cat "$CACHE_DIR/aur" 2>/dev/null || echo "0")
ORPHANS=$(cat "$CACHE_DIR/orphans" 2>/dev/null || echo "0")
CACHE=$(cat "$CACHE_DIR/cache_size" 2>/dev/null || echo "0")
JOURNAL=$(cat "$CACHE_DIR/journal" 2>/dev/null || echo "0")

[ "$OFFICIAL" = "?" ] && OFFICIAL=0
[ "$AUR" = "?" ] && AUR=0
TOTAL=$((OFFICIAL + AUR))

{
    checkupdates 2>/dev/null | wc -l > "$CACHE_DIR/official"
    yay -Qua 2>/dev/null | wc -l > "$CACHE_DIR/aur"
    pacman -Qdtq 2>/dev/null | wc -l > "$CACHE_DIR/orphans"
    sudo du -sh /var/cache/pacman/pkg/ 2>/dev/null | cut -f1 > "$CACHE_DIR/cache_size"
    journalctl --disk-usage 2>/dev/null | grep -oP '[\d.]+[KMGT]' > "$CACHE_DIR/journal"
} &

THEME="* {bg: #11111b; fg: #cdd6f4; sel: #1793d1; sf: #11111b; mb: #181825; br: #313244; font: \"JetBrainsMono Nerd Font 10\";}"
THEME="$THEME window {location: northwest; anchor: northwest; x-offset: 4px; y-offset: 34px; width: 300px; border: 2px solid; border-color: @br; border-radius: 16px; background-color: @bg;}"
THEME="$THEME mainbox {padding: 12px; background-color: transparent;}"
THEME="$THEME inputbar {enabled: false;}"
THEME="$THEME listview {lines: 7; fixed-height: false; scrollbar: false; spacing: 4px; background-color: transparent;}"
THEME="$THEME element {padding: 10px 15px; border-radius: 12px; background-color: @mb; text-color: @fg;}"
THEME="$THEME element normal.normal, element alternate.normal {background-color: @mb; text-color: @fg;}"
THEME="$THEME element selected.normal {background-color: @sel; text-color: @sf;}"
THEME="$THEME element-text {background-color: transparent; text-color: inherit;}"

CHOSEN=$(printf "Update All (%s pkgs)\nClean Package Cache (%s)\nRemove Orphans (%s pkgs)\nClean Journal Logs (%s)\nClean All\nView Updates\nClose" \
    "$TOTAL" "$CACHE" "$ORPHANS" "$JOURNAL" \
    | rofi -dmenu -i -p "System" -no-config -theme-str "$THEME")

case "$CHOSEN" in
    "Update All"*)
        kitty --title "System Update" -e bash -c "yay -Syu; echo; echo Done! Press Enter to close.; read" &
        ;;
    "Clean Package Cache"*)
        kitty --title "Clean Cache" -e bash -c "sudo paccache -r; yay -Scc --noconfirm; echo; echo Done! Press Enter to close.; read" &
        ;;
    "Remove Orphans"*)
        if pacman -Qdtq &>/dev/null; then
            kitty --title "Remove Orphans" -e bash -c "sudo pacman -Rns \$(pacman -Qdtq) --noconfirm; echo; echo Done! Press Enter to close.; read" &
        fi
        ;;
    "Clean Journal"*)
        kitty --title "Clean Journal" -e bash -c "sudo journalctl --vacuum-time=7d; echo; echo Done! Press Enter to close.; read" &
        ;;
    "Clean All"*)
        kitty --title "Full Cleanup" -e bash -c '
echo "=== Updating System ==="
yay -Syu
echo
echo "=== Cleaning Package Cache ==="
sudo paccache -r
echo
echo "=== Removing Orphans ==="
ORPHANS=$(pacman -Qdtq 2>/dev/null)
[ -n "$ORPHANS" ] && sudo pacman -Rns $ORPHANS --noconfirm || echo "No orphans found."
echo
echo "=== Cleaning Journal ==="
sudo journalctl --vacuum-time=7d
echo
echo "All done! Press Enter to close."
read
' &
        ;;
    "View Updates"*)
        kitty --title "Available Updates" -e bash -c '
echo "=== Official Repos ==="
checkupdates 2>/dev/null || echo "None"
echo
echo "=== AUR ==="
yay -Qua 2>/dev/null || echo "None"
echo
echo "Press Enter to close."
read
' &
        ;;
esac
