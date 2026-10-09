#!/bin/bash
#  ___              _
# / __| ___ ___ ___(_)___ _ _
# \__ \/ -_|_-<_-< / _ \ ' \
# |___/\___/__/__/_\___/_||_|
#
# Session helpers for hypridle: locking and post-resume display recovery.
#
#   lock   clear a wedged lock client, then run hyprlock
#   wake   force the display back on after resume

set -u

# A lock client younger than this is presumed to be still starting up.
STALE_AFTER=5

# Clock ticks of CPU per second above which a lock client is considered wedged.
# A healthy hyprlock sits in poll() at ~0; the one left behind by a crash on
# resume spun at ~145% of a core.
SPIN_TICKS=60

# Note: logind's LockedHint is useless here - neither Hyprland nor hyprlock
# ever calls SetLockedHint, so it never becomes "yes" and cannot be used to
# tell a live lock from a dead one. Measure the process instead.
is_spinning() {
	local pid=$1 t1 t2
	t1=$(awk '{print $14 + $15}' "/proc/$pid/stat" 2>/dev/null) || return 1
	sleep 1
	t2=$(awk '{print $14 + $15}' "/proc/$pid/stat" 2>/dev/null) || return 1
	((t2 - t1 > SPIN_TICKS))
}

# hypridle's stock `pidof hyprlock || hyprlock` does nothing when a previous
# hyprlock is alive but no longer holding the session lock. That is exactly
# what a hyprlock crash on resume leaves behind: the process spins, pidof
# succeeds, and the idle timeout then blanks the screen without ever locking
# it. See hyprwm/hyprlock#1048.
#
# A healthy lock client is never killed - that would restart the lock screen
# for no reason.
cmd_lock() {
	local pids pid age
	local -a wedged=()
	mapfile -t pids < <(pgrep -x hyprlock)

	for pid in "${pids[@]}"; do
		age=$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ')
		((${age:-0} < STALE_AFTER)) && exit 0
		is_spinning "$pid" && wedged+=("$pid")
	done

	# Something is locking the screen and it looks fine - leave it alone.
	((${#pids[@]} > 0)) && ((${#wedged[@]} == 0)) && exit 0

	if ((${#wedged[@]} > 0)); then
		echo ":: Clearing wedged hyprlock (${wedged[*]})" >&2
		kill -TERM "${wedged[@]}" 2>/dev/null
		sleep 1
		kill -KILL "${wedged[@]}" 2>/dev/null
	fi

	exec hyprlock
}

# hl.dsp.* build a dispatcher and return it; only hl.dispatch() runs one, and
# `hyprctl dispatch` is what wraps the code in hl.dispatch(). Just as
# important, hl.dsp.dpms() reads its action from a TABLE FIELD - any non-table
# argument (including `true`) falls through to TOGGLE, which turns the display
# off again when it is already on. The table form below is what forces it on.
cmd_wake() {
	exec hyprctl dispatch 'hl.dsp.dpms({ action = "on" })'
}

case "${1:-}" in
lock) cmd_lock ;;
wake) cmd_wake ;;
*)
	echo "usage: ${0##*/} {lock|wake}" >&2
	exit 1
	;;
esac
