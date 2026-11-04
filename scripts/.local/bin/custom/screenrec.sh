#!/bin/bash
# Screen recorder for demos: wl-screenrec (GPU/VAAPI, H.264) on a slurp selection.
#
#   screenrec.sh quick    stop if recording, else select a region and record with the mic
#   screenrec.sh menu     stop if recording, else pick the audio in rofi, then select and record
#   screenrec.sh stop     stop and save the current recording
#   screenrec.sh status   continuous JSON output for waybar (empty text hides the module)
#
# Audio modes: mic (default source), desktop (default sink's monitor), both (a
# temporary null sink fed by loopbacks from the two, torn down when recording
# ends), none.
#
# Selection: drag a region, or click a monitor to record all of it (slurp -o).
# Files land in ~/Videos/Recordings; the path is copied to the clipboard on save.

RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
STATE="$RUNTIME/screenrec.state"
LOCK="$RUNTIME/screenrec.lock"
LOG="$RUNTIME/screenrec.log"
OUT_DIR="$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")/Recordings"
MIX_SINK="screenrec_mix"

declare -A MODE_LABEL=([mic]="Mic" [desktop]="Desktop" [both]="Mic + desktop" [none]="No audio")

notify() {
	notify-send -a "Screen Recorder" -i media-record "$@"
}

# Sets PID / START / MODE / FILE, and returns success, only while a recording is live
load_state() {
	[ -f "$STATE" ] || return 1
	# shellcheck disable=SC1090
	. "$STATE"
	kill -0 "$PID" 2>/dev/null
}

unload_mix() {
	pactl list short modules | awk -v s="$MIX_SINK" '$0 ~ s {print $1}' | while read -r id; do
		pactl unload-module "$id"
	done
}

# SIGINT lets wl-screenrec finalise the mp4. If it is wedged (it busy-loops and
# ignores SIGINT on some inputs), escalate so stop always stops.
stop() {
	load_state || return 1
	kill -INT "$PID"
	for _ in $(seq 30); do
		kill -0 "$PID" 2>/dev/null || return 0
		sleep 0.1
	done
	kill -TERM "$PID" 2>/dev/null
	sleep 1
	kill -KILL "$PID" 2>/dev/null
	return 0
}

# Builds the wl-screenrec audio flags for a mode into the AUDIO array
audio_args() {
	AUDIO=()
	case "$1" in
	mic) AUDIO=(--audio) ;;
	desktop) AUDIO=(--audio --audio-device "$(pactl get-default-sink).monitor") ;;
	both)
		# Resolve defaults before the null sink exists, so it can't become one
		local src sink
		src=$(pactl get-default-source)
		sink=$(pactl get-default-sink)
		unload_mix
		pactl load-module module-null-sink sink_name="$MIX_SINK" \
			sink_properties=device.description=Screenrec-Mix >/dev/null || return 1
		pactl load-module module-loopback source="$src" sink="$MIX_SINK" latency_msec=20 >/dev/null || return 1
		pactl load-module module-loopback source="$sink.monitor" sink="$MIX_SINK" latency_msec=20 >/dev/null || return 1
		AUDIO=(--audio --audio-device "$MIX_SINK.monitor")
		;;
	none) ;;
	*) return 1 ;;
	esac
}

# Runs detached for the life of a recording: owns wl-screenrec, then cleans up and
# reports, so the mix modules are removed even if wl-screenrec dies on its own.
supervise() {
	local mode="$1" geom="$2" file="$3"
	trap 'unload_mix; rm -f "$STATE"' EXIT
	# Without job control, background children ignore SIGINT, which is how stop() ends them
	set -m

	if ! audio_args "$mode"; then
		notify -u critical "Recording failed" "Couldn't set up audio for mode: $mode"
		exit 1
	fi

	wl-screenrec -g "$geom" --codec avc --low-power=off -f "$file" "${AUDIO[@]}" >"$LOG" 2>&1 &
	local pid=$!
	printf 'PID=%s\nSTART=%s\nMODE=%s\nFILE=%q\n' "$pid" "$(date +%s)" "$mode" "$file" >"$STATE"
	wait "$pid"
	local rc=$?
	rm -f "$STATE"
	unload_mix

	# A killed recorder leaves a header-only mp4 behind, so check it actually plays
	if ! ffprobe -v error -show_entries format=duration "$file" >/dev/null 2>&1; then
		notify -u critical "Recording failed" "Recorder exited with $rc and left no playable file. $(tail -n 3 "$LOG")"
		rm -f "$file"
		exit 1
	fi

	printf '%s' "$file" | wl-copy
	# notify-send -A blocks until the notification is acted on or closed; don't linger forever
	case "$(timeout 120 notify -A open=Open -A folder="Show in folder" "Recording saved" "$(basename "$file") — path copied")" in
	open) mpv "$file" >/dev/null 2>&1 & ;;
	folder) nautilus --select "$file" >/dev/null 2>&1 & ;;
	esac
}

start() {
	local mode="$1"
	# One start at a time: a second press while slurp/rofi is open does nothing
	exec 9>"$LOCK"
	flock -n 9 || exit 0

	if [ "$mode" = "pick" ]; then
		local choice
		choice=$(printf '%s\n' "${MODE_LABEL[mic]}" "${MODE_LABEL[desktop]}" "${MODE_LABEL[both]}" "${MODE_LABEL[none]}" |
			rofi -dmenu -i -p "Record audio") || exit 0
		for key in "${!MODE_LABEL[@]}"; do
			[ "${MODE_LABEL[$key]}" = "$choice" ] && mode="$key"
		done
		[ "$mode" = "pick" ] && exit 0
	fi

	# wl-screenrec hangs (100% CPU, ignores SIGINT) on odd-sized H.264 regions, so
	# round the size down to even
	local sel x y w h
	sel=$(slurp -o -f '%x %y %w %h') || exit 0
	read -r x y w h <<<"$sel"
	w=$((w & ~1)) h=$((h & ~1))
	[ "$w" -ge 2 ] && [ "$h" -ge 2 ] || exit 0
	local geom="$x,$y ${w}x${h}"

	mkdir -p "$OUT_DIR"
	local file
	file="$OUT_DIR/$(date +%Y-%m-%d_%H-%M-%S).mp4"
	setsid "$0" _supervise "$mode" "$geom" "$file" >/dev/null 2>&1 9>&- &
}

status() {
	local last=""
	while true; do
		local line
		if load_state; then
			local elapsed=$(($(date +%s) - START))
			local t
			t=$(printf '%02d:%02d' $((elapsed / 60)) $((elapsed % 60)))
			line=$(printf '{"text":"● %s","class":"recording","tooltip":"Recording (%s) — click to stop"}' \
				"$t" "${MODE_LABEL[$MODE]}")
		else
			line='{"text":"","class":"idle"}'
		fi
		[ "$line" != "$last" ] && echo "$line" && last="$line"
		sleep 1
	done
}

case "$1" in
quick) stop || start mic ;;
menu) stop || start pick ;;
stop) stop ;;
status) status ;;
_supervise) shift && supervise "$@" ;;
*)
	echo "Usage: $0 {quick|menu|stop|status}"
	exit 1
	;;
esac
