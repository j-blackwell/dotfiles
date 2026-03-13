# /// script
# requires-python = ">=3.13"
# dependencies = []
# ///

# sudo nano /etc/udev/rules.d/99-hypr-monitor-hotplug.rules
# sudo udevadm control --reload-rules
# sudo udevadm trigger

import subprocess


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


def set_laptop_only(internal):
    cmd = f"hyprctl keyword monitor {internal}, preferred, auto, 1"
    subprocess.run(cmd, shell=True)


def handle_unplug():
    internal = "eDP-1"
    monitors = get_monitors()
    if len([m for m in monitors if m != internal]) == 0:
        set_laptop_only(internal)


if __name__ == "__main__":
    handle_unplug()
