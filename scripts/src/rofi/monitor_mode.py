# /// script
# requires-python = ">=3.13"
# dependencies = []
# ///

import subprocess
import time
from typing import Optional


# Detect monitors using `hyprctl`
def get_monitors():
    result = subprocess.run(
        ["hyprctl", "monitors", "all"],
        capture_output=True,
        text=True,
    )
    lines = result.stdout.splitlines()
    monitors = [line.split()[1] for line in lines if line.startswith("Monitor")]
    return monitors


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


# Show Rofi menu
def monitor_picker():
    monitors = get_monitors()
    internal = "eDP-1"

    # If only the internal monitor exists, only show "Laptop Only"
    if len(monitors) == 1 and internal in monitors:
        options = ["Laptop Only"]
        external = None
    else:
        external_monitors = [m for m in monitors if m != internal]
        if not external_monitors:
            external = None
            options = ["Laptop Only"]
        else:
            external = external_monitors[0]
            options = ["Extend", "Laptop Only", "External Only", "Mirror (Duplicate)"]

    menu = "\n".join(options)

    result = subprocess.run(
        ["rofi", "-dmenu", "-i", "-p", "Select display mode"],
        input=menu,
        text=True,
        capture_output=True,
    )
    selected_mode = result.stdout.strip()
    set_monitor_mode(selected_mode, internal, external)


if __name__ == "__main__":
    monitor_picker()
