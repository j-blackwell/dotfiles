#!/bin/bash

# Configuration: Pass MAC address as first argument or hardcode it here
# Defaulting to ST DISCO (00:16:74:F0:43:44)
DEVICE_MAC="${1:-00:16:74:F0:43:44}"
DEVICE_NAME=$(bluetoothctl info "$DEVICE_MAC" | grep "Name:" | cut -d ' ' -f 2-)

if [ -z "$DEVICE_NAME" ]; then
    notify-send "Bluetooth" "Device $DEVICE_MAC not found or not paired." -u critical
    exit 1
fi

# Check if already connected
if bluetoothctl info "$DEVICE_MAC" | grep -q "Connected: yes"; then
    notify-send "Bluetooth" "Disconnecting from $DEVICE_NAME..."
    if bluetoothctl disconnect "$DEVICE_MAC" > /dev/null 2>&1; then
        notify-send "Bluetooth" "Successfully disconnected from $DEVICE_NAME."
    else
        notify-send "Bluetooth" "Failed to disconnect from $DEVICE_NAME." -u critical
        exit 1
    fi
    exit 0
fi

notify-send "Bluetooth" "Attempting to connect to $DEVICE_NAME..."

# Try to connect
if bluetoothctl connect "$DEVICE_MAC" > /dev/null 2>&1; then
    notify-send "Bluetooth" "Successfully connected to $DEVICE_NAME."
else
    notify-send "Bluetooth" "Failed to connect to $DEVICE_NAME. Is it turned on?" -u critical
    exit 1
fi
