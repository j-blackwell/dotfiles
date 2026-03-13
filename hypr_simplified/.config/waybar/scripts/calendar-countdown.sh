#!/bin/bash

# Configuration
GCALCLI="gcalcli --nocolor"
# Detect the owner calendar if not specified
CALENDAR=$($GCALCLI list | grep "owner" | awk '{print $NF}' | head -n 1)

# Fetch agenda for the next 2 days to ensure we catch tomorrow morning
# We store it in a variable to reuse for the tooltip
AGENDA=$($GCALCLI agenda "$(date +%Y-%m-%d)" "$(date -d '+2 days' +%Y-%m-%d)" --calendar "$CALENDAR" --nodeclined 2>/dev/null)

if [ -z "$AGENDA" ]; then
	echo '{"text": "", "tooltip": "No upcoming events"}'
	exit 0
fi

NOW=$(date +%s)
EVENT_DATE=""
DATE_STR=""
NEXT_EVENT_TEXT=""
NEXT_EVENT_TOOLTIP=""

# Find the next upcoming event for the bar text
while IFS= read -r line; do
	[[ -z "$line" ]] && continue

	# 1. Detect Date Headers (e.g., "Fri Mar 13")
	if [[ $line =~ ^([A-Z][a-z]{2}\ [A-Z][a-z]{2}\ +[0-9]{1,2}) ]]; then
		DATE_STR="${BASH_REMATCH[1]}"
		EVENT_DATE=$(date -d "$DATE_STR" +%Y-%m-%d 2>/dev/null)
		continue
	fi

	# 2. Detect Timed Events (e.g., " 16:30 ")
	if [[ $line =~ ^[[:space:]]+([0-9]{1,2}:[0-9]{2}) ]]; then
		TIME_STR="${BASH_REMATCH[1]}"

		if [ -n "$EVENT_DATE" ]; then
			EVENT_EPOCH=$(date -d "$EVENT_DATE $TIME_STR" +%s 2>/dev/null)

			# Check if the event is in the future
			if [ -n "$EVENT_EPOCH" ] && [ "$EVENT_EPOCH" -gt "$NOW" ]; then
				# Extract title
				TITLE=$(echo "$line" | sed -E "s/^[[:space:]]+[0-9]{1,2}:[0-9]{2}([[:space:]]+[0-9]{1,2}:[0-9]{2})?[[:space:]]+//")

				DIFF=$((EVENT_EPOCH - NOW))
				HOURS=$((DIFF / 3600))
				MINS=$(((DIFF % 3600) / 60))

				if [ "$HOURS" -gt 0 ]; then
					NEXT_EVENT_TEXT="${HOURS}h ${MINS}m: $TITLE"
				else
					NEXT_EVENT_TEXT="${MINS}m: $TITLE"
				fi
				break
			fi
		fi
	fi
done <<<"$AGENDA"

# Format the full agenda for the tooltip
# We'll clean it up slightly (remove extra blank lines) and escape for JSON
# We use printf %q or similar to handle newlines, but for Waybar JSON, we need actual \n strings
CLEAN_AGENDA=$(echo "$AGENDA" | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

# Escape quotes in NEXT_EVENT_TEXT
NEXT_EVENT_TEXT=$(echo "$NEXT_EVENT_TEXT" | sed 's/"/\\"/g')

if [ -n "$NEXT_EVENT_TEXT" ]; then
	echo "{\"text\": \"  $NEXT_EVENT_TEXT\", \"tooltip\": \"$CLEAN_AGENDA\"}"
else
	echo "{\"text\": \"\", \"tooltip\": \"$CLEAN_AGENDA\"}"
fi
