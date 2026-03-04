#!/bin/bash

# Define the directory and filename
DIR="$HOME/Pictures/bing_wallpaper"
TODAY=$(date +"%Y-%m-%d")
DATE_FILE="$DIR/$TODAY.jpg"
CURRENT_FILE="$DIR/current.jpg"

# Create the directory if it doesn't exist
mkdir -p "$DIR"

# Download the Bing wallpaper if not already done today
if [ ! -f "$DATE_FILE" ]; then
    echo ":: Downloading Bing wallpaper for $TODAY..."
    BING_URL="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1"
    IMAGE_URL=$(curl -s "$BING_URL" | jq -r '.images[0].url' | sed 's/^/https:\/\/www.bing.com/')
    
    if curl -s -o "$DATE_FILE" "$IMAGE_URL"; then
        cp "$DATE_FILE" "$CURRENT_FILE"
    else
        echo ":: Error: Failed to download wallpaper."
        exit 1
    fi
fi

# Ensure hyprpaper is running
if ! pidof hyprpaper > /dev/null; then
    hyprpaper &
    # Wait for the hyprpaper socket to be created
    for i in {1..30}; do
        if hyprctl hyprpaper listloaded >/dev/null 2>&1; then
            break
        fi
        sleep 0.1
    done
fi

hyprctl hyprpaper wallpaper ",$CURRENT_FILE"

