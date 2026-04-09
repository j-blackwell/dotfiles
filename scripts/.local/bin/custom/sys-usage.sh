#!/bin/bash

BLOCKS=($'\u2581' $'\u2582' $'\u2583' $'\u2584' $'\u2585' $'\u2586' $'\u2587' $'\u2588')

CPU_DATA=$(grep '^cpu ' /proc/stat)
CPU_TOTAL=$(echo "$CPU_DATA" | awk '{print $2+$3+$4+$5+$6+$7+$8+$9}')
CPU_IDLE=$(echo "$CPU_DATA" | awk '{print $5+$6}')

sleep 0.5

CPU_DATA2=$(grep '^cpu ' /proc/stat)
CPU_TOTAL2=$(echo "$CPU_DATA2" | awk '{print $2+$3+$4+$5+$6+$7+$8+$9}')
CPU_IDLE2=$(echo "$CPU_DATA2" | awk '{print $5+$6}')

DIFF_TOTAL=$((CPU_TOTAL2 - CPU_TOTAL))
if [ "$DIFF_TOTAL" -eq 0 ]; then
    CPU_USAGE=0
else
    CPU_USAGE=$(awk "BEGIN {print int(100 * ($DIFF_TOTAL - ($CPU_IDLE2 - $CPU_IDLE)) / $DIFF_TOTAL)}")
fi

RAM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')

get_block() {
    local val=$1
    local idx=$(( (val * 7 + 50) / 100 ))
    echo "${BLOCKS[$idx]}"
}

CPU_BLOCK=$(get_block "$CPU_USAGE")
RAM_BLOCK=$(get_block "$RAM_USAGE")

# Use printf with double escaped newline to get \n in the output string
printf '{"text": "C %s %s R", "tooltip": "CPU: %d%%\\nRAM: %d%%"}\n' "$CPU_BLOCK" "$RAM_BLOCK" "$CPU_USAGE" "$RAM_USAGE"
