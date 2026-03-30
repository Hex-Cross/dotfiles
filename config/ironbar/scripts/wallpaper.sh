#!/bin/bash
# macOS-style wallpaper picker using nsxiv thumbnail mode
# Click an image to set it as wallpaper

WALLDIR="$HOME/Pictures/Wallpapers"
mkdir -p "$WALLDIR"

# Check for images
COUNT=$(find "$WALLDIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | wc -l)

# Also check ~/Pictures root
if [ "$COUNT" -eq 0 ]; then
    WALLDIR="$HOME/Pictures"
    COUNT=$(find "$WALLDIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | wc -l)
fi

if [ "$COUNT" -eq 0 ]; then
    notify-send "Wallpaper" "No images found. Put images in ~/Pictures/Wallpapers/"
    exit 0
fi

# Open nsxiv in thumbnail mode, output selected file
SELECTED=$(find "$WALLDIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | sort | nsxiv -t -o -g 800x500 2>/dev/null)

[ -z "$SELECTED" ] && exit 0

MONITOR=$(hyprctl monitors -j | grep -oP '"name":\s*"\K[^"]+' | head -1)
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

# Check if swww is available for smooth transitions
if command -v swww-daemon &>/dev/null || pgrep -x swww-daemon &>/dev/null; then
    # Use swww for smooth fade
    swww img "$SELECTED" --transition-type fade --transition-duration 1
else
    # Fall back to hyprpaper
    hyprctl hyprpaper unload all 2>/dev/null
    hyprctl hyprpaper preload "$SELECTED" 2>/dev/null
    hyprctl hyprpaper wallpaper "$MONITOR,$SELECTED" 2>/dev/null
    
    # Save config
    cat > "$HYPRPAPER_CONF" << EOF
preload = $SELECTED
wallpaper = $MONITOR,$SELECTED
splash = false
ipc = on
EOF
fi
