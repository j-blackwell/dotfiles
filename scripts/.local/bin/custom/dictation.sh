#!/bin/bash
# Thin wrapper around hyprwhspr for Hyprland binds and the waybar module.
#
#   dictation.sh press [hold_delay]  push-to-talk key down; only starts recording
#                                    if the key is still held after hold_delay
#                                    seconds, so ordinary clicks are ignored
#   dictation.sh release             push-to-talk key up
#   dictation.sh toggle              start/stop hands-free recording
#   dictation.sh status              continuous JSON output for waybar

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hyprwhspr"
CONTROL_FIFO="$RUNTIME_DIR/recording_control"
RECORDING_FILE="$RUNTIME_DIR/recording_status"
PTT_STATE="${XDG_RUNTIME_DIR:-/tmp}/dictation-ptt"

# Writing to the FIFO blocks forever if the daemon isn't reading it
send() {
	[ -p "$CONTROL_FIFO" ] && timeout 1 sh -c 'echo "$1" > "$2"' _ "$1" "$CONTROL_FIFO"
}

emit() {
	printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$1" "$2" "$3"
}

case "$1" in
press)
	echo "$$" >"$PTT_STATE"
	sleep "${2:-0}"
	# A release (or a newer press) during the delay owns the state file now
	[ "$(cat "$PTT_STATE" 2>/dev/null)" = "$$" ] || exit 0
	echo "started" >"$PTT_STATE"
	send start
	;;
release)
	state=$(cat "$PTT_STATE" 2>/dev/null)
	rm -f "$PTT_STATE"
	[ "$state" = "started" ] && send release
	;;
toggle)
	hyprwhspr record toggle
	;;
status)
	last=""
	while true; do
		if [ -e "$RECORDING_FILE" ]; then
			current="recording"
		elif [ -p "$CONTROL_FIFO" ]; then
			current="idle"
		else
			current="off"
		fi
		if [ "$current" != "$last" ]; then
			case "$current" in
			recording) emit "󰍬" "recording" "Dictation: recording" ;;
			idle) emit "󰍬" "idle" "Dictation: ready" ;;
			off) emit "󰍭" "off" "Dictation: service not running" ;;
			esac
			last="$current"
		fi
		sleep 0.2
	done
	;;
*)
	echo "Usage: $0 {press [hold_delay]|release|toggle|status}"
	exit 1
	;;
esac
