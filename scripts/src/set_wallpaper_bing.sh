#!/bin/sh

# Define the directory and filename
DIR="$HOME/Pictures/bing_wallpaper"
TODAY=$(date +"%Y-%m-%d")
DATE_FILE="$DIR/$TODAY.jpg"
CURRENT_FILE="$DIR/current.jpg"

# Create the directory if it doesn't exist
mkdir -p "$DIR"

# Download the Bing wallpaper
BING_URL="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1"
IMAGE_URL=$(curl -s "$BING_URL" | jq -r '.images[0].url' | sed 's/^/https:\/\/www.bing.com/')

# Download the Bing wallpaper
curl -s -o "$DATE_FILE" "$IMAGE_URL"

# Copy the downloaded file to "today.jpg"
cp "$DATE_FILE" "$CURRENT_FILE"

feh --bg-fill $CURRENT_FILE
