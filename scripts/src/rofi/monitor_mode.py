# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///

import subprocess
import time
import os
from typing import Optional

STATE_FILE = "/tmp/hypr-monitor-mode.txt"  # Stores the last used mode


# Detect connected monitors using `hyprctl`
def get_monitors():
    result = subprocess.run(
        ["hyprctl", "monitors", "all"],
        capture_output=True,
        text=True,
    )
    lines = result.stdout.splitlines()
    monitors = [line.split()[1] for line in lines if line.startswith("Monitor")]
    return monitors


# Apply monitor configuration
def set_monitor_mode(mode, internal, external: Optional[str] = None):
    if mode == "Extend":
        commands = [
            f"hyprctl keyword monitor {internal}, preferred, auto, 1",
            f"hyprctl keyword monitor {external}, preferred, auto, 1",
        ]
    elif mode == "Laptop Only":
        commands = [f"hyprctl keyword monitor {internal}, preferred, auto, 1"]
        if external is not None:
            commands.append(f"hyprctl keyword monitor {external}, disable")
    elif mode == "External Only":
        commands = [
            f"hyprctl keyword monitor {external}, preferred, auto, 1",
            f"hyprctl keyword monitor {internal}, disable",
        ]
    elif mode == "Mirror (Duplicate)":
        commands = [
            f"hyprctl keyword monitor {internal}, preferred, auto, 1",
            f"hyprctl keyword monitor {external}, preferred, auto, 1, mirror,{internal}",
        ]
    else:
        return

    for cmd in commands:
        subprocess.run(cmd, shell=True)
        time.sleep(0.5)

    # Save the current mode
    with open(STATE_FILE, "w") as f:
        f.write(mode)


# Cycle through display modes
def cycle_monitor_modes():
    monitors = get_monitors()
    internal = "eDP-1"

    # Detect external monitor
    external_monitors = [m for m in monitors if m != internal]
    if len(external_monitors) == 0:
        return set_monitor_mode("Laptop Only", internal, None)

    external = external_monitors[0]
    modes = ["Extend", "Laptop Only", "External Only", "Mirror (Duplicate)"]
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE, "r") as f:
            last_mode = f.read().strip()
    else:
        last_mode = "Laptop Only"

    # Get next mode in the cycle
    next_mode = modes[(modes.index(last_mode) + 1) % len(modes)]

    print(f"Switching to: {next_mode}")
    set_monitor_mode(next_mode, internal, external)


if __name__ == "__main__":
    cycle_monitor_modes()
