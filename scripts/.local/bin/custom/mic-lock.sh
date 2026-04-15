#!/bin/bash

# Configuration
PIDFILE="/tmp/mic-lock.pid"

# Function to run the lock loop
run_lock() {
    echo "Starting Mic Lock using Base Volume as reference..."
    
    # Cleanup on exit
    trap "rm -f $PIDFILE; exit" SIGINT SIGTERM EXIT

    while true; do
        # Get all sources in JSON format, filtering for physical sources (not monitors)
        pactl --format=json list sources | jq -c '.[] | select(.monitor_source == "")' | while read -r source; do
            NAME=$(echo "$source" | jq -r '.name')
            # Extract base volume raw value for precision comparison
            BASE_RAW=$(echo "$source" | jq -r '.base_volume.value')
            # Extract base volume percent for setting the target
            BASE_PCT=$(echo "$source" | jq -r '.base_volume.value_percent' | tr -dc '0-9')
            # Extract current volume raw value
            CURR_RAW=$(echo "$source" | jq -r '.volume | to_entries[0].value.value')
            
            # Ensure we have valid numbers before comparing using raw precision
            if [[ -n "$CURR_RAW" && -n "$BASE_RAW" ]] && [ "$CURR_RAW" -lt "$BASE_RAW" ]; then
                TARGET=$((BASE_PCT + 1))
                pactl set-source-volume "$NAME" "${TARGET}%"
            fi
        done
        sleep 1
    done
}

# Toggle logic
case "$1" in
    run)
        run_lock
        ;;
    toggle)
        if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
            # Stop the lock
            kill $(cat "$PIDFILE")
            rm -f "$PIDFILE"
            notify-send -u low -t 2000 "Mic Lock" "Disabled" -i audio-input-microphone-muted
        else
            # Start the lock
            # Ensure no orphan processes are running
            pkill -f "mic-lock.sh run" 2>/dev/null
            $0 run >/dev/null 2>&1 &
            echo $! > "$PIDFILE"
            notify-send -u low -t 2000 "Mic Lock" "Enabled (Base + 1%)" -i audio-input-microphone
        fi
        ;;
    *)
        echo "Usage: $0 {run|toggle}"
        exit 1
        ;;
esac
