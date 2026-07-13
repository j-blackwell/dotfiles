#!/bin/bash

# Configuration
PIDFILE="/tmp/mic-lock.pid"
STATEFILE="/tmp/mic-lock.state"

# Function to run the lock loop
run_lock() {
    echo "Starting Mic Lock daemon..."
    
    # Cleanup on exit
    trap "rm -f $PIDFILE; exit" SIGINT SIGTERM EXIT

    while true; do
        # Read target state (default to 150 if statefile is missing/empty)
        TARGET=$(cat "$STATEFILE" 2>/dev/null || echo "150")
        
        # Get all sources in JSON format, filtering for physical sources (not monitors)
        pactl --format=json list sources | jq -c '.[] | select(.monitor_source == "")' | while read -r source; do
            NAME=$(echo "$source" | jq -r '.name')
            # Extract current volume percent (first channel)
            CURR_PCT=$(echo "$source" | jq -r '.volume | to_entries[0].value.value_percent' | tr -dc '0-9')
            
            # Ensure we have valid numbers before comparing
            if [[ -n "$CURR_PCT" ]] && [ "$CURR_PCT" -ne "$TARGET" ]; then
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
        # Determine current state, default to 150
        CURRENT_STATE=$(cat "$STATEFILE" 2>/dev/null || echo "150")
        if [ "$CURRENT_STATE" = "150" ]; then
            NEW_STATE="0"
            MSG="Locked to 0%"
            ICON="audio-input-microphone-muted"
        else
            NEW_STATE="150"
            MSG="Locked to Max (150%)"
            ICON="audio-input-microphone"
        fi
        
        # Write new state
        echo "$NEW_STATE" > "$STATEFILE"
        
        # Ensure daemon is running
        if [ ! -f "$PIDFILE" ] || ! kill -0 $(cat "$PIDFILE") 2>/dev/null; then
            pkill -f "mic-lock.sh run" 2>/dev/null
            $0 run >/dev/null 2>&1 &
            echo $! > "$PIDFILE"
        fi
        
        notify-send -u low -t 2000 "Mic Lock" "$MSG" -i "$ICON"
        ;;
    stop)
        if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
            kill $(cat "$PIDFILE")
            rm -f "$PIDFILE" "$STATEFILE"
            notify-send -u low -t 2000 "Mic Lock" "Stopped" -i audio-input-microphone-muted
        else
            echo "Mic Lock is not running."
        fi
        ;;
    status)
        if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
            CURRENT_STATE=$(cat "$STATEFILE" 2>/dev/null || echo "150")
            echo "Mic Lock is running (PID: $(cat $PIDFILE)). Current target volume: ${CURRENT_STATE}%."
        else
            echo "Mic Lock is stopped."
        fi
        ;;
    *)
        echo "Usage: $0 {run|toggle|stop|status}"
        exit 1
        ;;
esac
