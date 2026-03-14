#!/bin/bash

# Script: port-opener.sh
# Description: Lists listening ports on localhost, shows processes in rofi, opens selected port in Chrome

# Check if rofi is installed
if ! command -v rofi &> /dev/null; then
    echo "Error: rofi is not installed. Install with: sudo pacman -S rofi"
    exit 1
fi

# Check if google-chrome is available (try different chrome variants)
chrome_cmd=""
if command -v google-chrome &> /dev/null; then
    chrome_cmd="google-chrome"
elif command -v chromium &> /dev/null; then
    chrome_cmd="chromium"
elif command -v google-chrome-stable &> /dev/null; then
    chrome_cmd="google-chrome-stable"
else
    echo "Error: No Chrome/Chromium browser found. Install with:"
    echo "  sudo pacman -S chromium  # or"
    echo "  yay -S google-chrome     # from AUR"
    exit 1
fi

# Get listening ports with better process detection
ports_info=$(ss -tlnp | grep "127.0.0.1:" | while IFS= read -r line; do
    port=$(echo "$line" | awk '{print $4}' | cut -d':' -f2)
    
    # Try to extract PID first, then get process name from /proc
    pid=$(echo "$line" | grep -o 'pid=[0-9]*' | cut -d'=' -f2)
    
    if [[ -n "$pid" ]] && [[ -r "/proc/$pid/comm" ]]; then
        process_name=$(cat "/proc/$pid/comm" 2>/dev/null)
        echo "$port - $process_name"
    else
        # Fallback to the users field method
        process_info=$(echo "$line" | grep -o 'users:(([^)]*))' | sed 's/users:((//' | sed 's/))//')
        if [[ -n "$process_info" ]]; then
            process_name=$(echo "$process_info" | cut -d',' -f2 | tr -d '"' | tr -d ' ')
            echo "$port - $process_name"
        else
            echo "$port - unknown"
        fi
    fi
done | sort -n)

# Check if any ports were found
if [[ -z "$ports_info" ]]; then
    rofi -e "No listening ports found on 127.0.0.1"
    exit 0
fi

# Show ports in rofi and get selection
selected=$(echo "$ports_info" | rofi -dmenu -p "Select port to open:" -i)

# Check if user made a selection
if [[ -z "$selected" ]]; then
    exit 0
fi

# Extract port number from selection
port=$(echo "$selected" | cut -d' ' -f1)

# Validate port number
if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    rofi -e "Invalid port number: $port"
    exit 1
fi

# Open the selected port in Chrome/Chromium
$chrome_cmd --new-window "http://127.0.0.1:$port" &

echo "Opening http://127.0.0.1:$port in $chrome_cmd..."
