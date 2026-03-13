#!/bin/bash

STATE_FILE="/tmp/pomodoro_state"
WORK_DURATION=1500
BREAK_DURATION=300

# Function to save state
save_state() {
	echo "$1 $2 $3" >"$STATE_FILE"
}

# Load state
if [ ! -f "$STATE_FILE" ]; then
	save_state "idle" "$WORK_DURATION" "work"
fi
read -r state val mode <"$STATE_FILE"

now=$(date +%s)

if [ "$state" == "running" ]; then
	remaining=$((val - now))
	if [ "$remaining" -le 0 ]; then
		if [ "$mode" == "work" ]; then
			state="idle"
			val=$BREAK_DURATION
			mode="break"
			notify-send "Pomodoro" "Work session finished! Take a break." -i clock
		else
			state="idle"
			val=$WORK_DURATION
			mode="work"
			notify-send "Pomodoro" "Break finished! Back to work." -i clock
		fi
		save_state "$state" "$val" "$mode"
		remaining=$val
	fi
else
	remaining=$val
fi

case "$1" in
"toggle")
	if [ "$state" == "running" ]; then
		save_state "paused" "$remaining" "$mode"
	else
		save_state "running" "$((now + remaining))" "$mode"
	fi
	;;
"reset")
	if [ "$mode" == "work" ]; then
		save_state "idle" "$WORK_DURATION" "work"
	else
		save_state "idle" "$BREAK_DURATION" "break"
	fi
	;;
"add")
	if [ "$state" == "running" ]; then
		save_state "running" "$((val + 60))" "$mode"
	else
		save_state "$state" "$((val + 60))" "$mode"
	fi
	;;
"sub")
	new_val=$((remaining - 60))
	[ "$new_val" -lt 0 ] && new_val=0
	if [ "$state" == "running" ]; then
		save_state "running" "$((now + new_val))" "$mode"
	else
		save_state "$state" "$new_val" "$mode"
	fi
	;;
*)
	mins=$((remaining / 60))
	secs=$((remaining % 60))
	time_str=$(printf "%02d:%02d" $mins $secs)

	if [ "$mode" == "work" ]; then
		icon="󱎫"
	else
		icon="󱫞"
	fi

	if [ "$state" == "paused" ]; then
		icon="󱎭"
	elif [ "$state" == "idle" ]; then
		icon="󱎮"
	fi

	text="$icon $time_str"
	tooltip="State: $state\nMode: $mode\nRemaining: $time_str"
	class="$mode-$state"

	echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\", \"class\": \"$class\"}"
	;;
esac
