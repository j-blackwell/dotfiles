#!/bin/bash
# Get all windows in current workspace
active_workspace=$(hyprctl activeworkspace -j | jq -r '.id')
ungrouped_windows=$(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $active_workspace and .grouped == []) | .address")
grouped_windows=$(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $active_workspace and .grouped != []) | .address")
ungrouped_count=$(echo "$ungrouped_windows" | wc -w)
grouped_count=$(echo "$grouped_windows" | wc -w)

echo "Found grouped windows: $grouped_windows"
echo "Found ungrouped windows: $ungrouped_windows"

# Create group on first window

if [ $((ungrouped_count + grouped_count)) -lt 2 ]; then
    exit 0
fi

if [ "$grouped_count" -gt 0 ]; then
    hyprctl dispatch togglegroup
else
    first=true
    for window in $ungrouped_windows; do
        if [ "$first" = true ]; then
            hyprctl dispatch focuswindow address:$window
            hyprctl dispatch togglegroup
            first=false
            echo "Created group on $window"
        else
            hyprctl dispatch focuswindow address:$window
            # Try all directions to find the group
            for direction in l r u d; do
                result=$(hyprctl dispatch movewindoworgroup $direction 2>&1)
                if [[ ! "$result" =~ "Invalid" ]]; then
                    echo "Added $window to group via direction $direction"
                    break
                fi
            done
        fi
    done
fi
