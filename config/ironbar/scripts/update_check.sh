#!/bin/bash
# Checks for updates using a cache file to avoid lag
CACHE="/tmp/ironbar_updates"

# If cache exists and is less than 10 min old, use it
if [ -f "$CACHE" ] && [ $(($(date +%s) - $(stat -c %Y "$CACHE"))) -lt 600 ]; then
    cat "$CACHE"
    exit 0
fi

# Run check in background and write to cache
{
    OFFICIAL=$(checkupdates 2>/dev/null | wc -l)
    AUR=$(yay -Qua 2>/dev/null | wc -l)
    TOTAL=$((OFFICIAL + AUR))
    if [ "$TOTAL" -eq 0 ]; then
        echo "Up to date" > "$CACHE"
    else
        echo "$TOTAL updates" > "$CACHE"
    fi
} &

# Show cached or placeholder
if [ -f "$CACHE" ]; then
    cat "$CACHE"
else
    echo "Checking..."
fi
