#!/bin/bash

# Configuration
MAX_SPEED=10485760 # 10MB/s
BAR_WIDTH=5

# Detect the default interface
INTERFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n 1)

if [ -z "$INTERFACE" ]; then
	echo '{"text": "󰲛 ", "tooltip": "Disconnected"}'
	exit 0
fi

# Get initial bytes
RX1=$(cat "/sys/class/net/$INTERFACE/statistics/rx_bytes")
TX1=$(cat "/sys/class/net/$INTERFACE/statistics/tx_bytes")
sleep 1
RX2=$(cat "/sys/class/net/$INTERFACE/statistics/rx_bytes")
TX2=$(cat "/sys/class/net/$INTERFACE/statistics/tx_bytes")

# Calculate speed (Bytes per second)
RX_SPEED=$((RX2 - RX1))
TX_SPEED=$((TX2 - TX1))

# Helper to format human readable bits (matching original module's style)
format_bits() {
	local speed=$(($1 * 8))
	if [ "$speed" -ge 1000000 ]; then
		awk "BEGIN {printf \"%.1f Mb/s\", $speed/1000000}"
	elif [ "$speed" -ge 1000 ]; then
		awk "BEGIN {printf \"%.1f Kb/s\", $speed/1000}"
	else
		echo "$speed b/s"
	fi
}

DOWN_BITS=$(format_bits "$RX_SPEED")
UP_BITS=$(format_bits "$TX_SPEED")

# Get IP
IP=$(ip -4 addr show "$INTERFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Check if Wifi or Ethernet and get details
IF_INFO=$(nmcli -t -f DEVICE,TYPE,STATE dev | grep "^$INTERFACE")
TYPE=$(echo "$IF_INFO" | cut -d: -f2)

if [[ "$TYPE" == "wifi" ]]; then
	WIFI_INFO=$(nmcli -t -f IN-USE,SSID,SIGNAL,BARS,FREQ dev wifi | grep '^\*')
	ESSID=$(echo "$WIFI_INFO" | cut -d: -f2)
	SIGNAL=$(echo "$WIFI_INFO" | cut -d: -f3)
	FREQ=$(echo "$WIFI_INFO" | cut -d: -f5)
	TOOLTIP="$ICON  $INTERFACE @ $ESSID\nIP: $IP\nStrength: $SIGNAL%\nFreq: $FREQ\nUp: $UP_BITS\nDown: $DOWN_BITS"
else
	TOOLTIP="$ICON $INTERFACE\nIP: $IP\n up: $UP_BITS down: $DOWN_BITS"
fi

# Calculate bandwidth level (0-4)
# Ratio = log(speed+1) / log(max+1)
RATIO=$(awk "BEGIN { r = log($RX_SPEED+1)/log($MAX_SPEED+1); if(r>1)r=1; print r }")
LEVEL=$(awk "BEGIN { print int($RATIO * 4 + 0.5) }")

# Map level to Nerd Font wifi-strength icons
# 0: 󰤯, 1: 󰤟, 2: 󰤢, 3: 󰤥, 4: 󰤨
ICONS=("󰤯" "󰤟" "󰤢" "󰤥" "󰤨")
STRENGTH_ICON=${ICONS[$LEVEL]}

# Output JSON
echo "{\"text\": \"$STRENGTH_ICON\", \"tooltip\": \"$TOOLTIP\"}"
