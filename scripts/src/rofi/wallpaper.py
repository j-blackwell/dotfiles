# /// script
# requires-python = ">=3.13"
# dependencies = [
# ]
# ///

import subprocess
import time
from pathlib import Path


def wallpaper_picker():
    wallpaper_dir = Path("~/Pictures/bing_wallpaper/").expanduser()

    # Create entries with icon metadata for Rofi
    # Format: Label\0icon\x1f/path/to/icon
    entries = []
    for x in sorted(wallpaper_dir.glob("*.jpg"), reverse=True):
        entries.append(f"{x.name}\0icon\x1f{x.absolute()}")

    wallpaper_menu = "\n".join(entries)

    result = subprocess.run(
        [
            "rofi",
            "-dmenu",
            "-i",
            "-p",
            "Pick a wallpaper",
            "-show-icons",
            # Grid layout with large previews
            "-theme-str",
            "element { orientation: vertical; } element-icon { size: 10em; } element-text { horizontal-align: 0.5; } listview { columns: 4; lines: 2; } window { width: 1000px; }",
        ],
        input=wallpaper_menu,
        text=True,
        capture_output=True,
    )
    selected_line = result.stdout.strip()

    if selected_line:
        selected_wallpaper = selected_line.strip()
        selected_path = Path(wallpaper_dir, selected_wallpaper).resolve()

        # Ensure hyprpaper is running
        try:
            subprocess.run(["pidof", "hyprpaper"], check=True, capture_output=True)
        except subprocess.CalledProcessError:
            subprocess.Popen(["hyprpaper"])
            time.sleep(1)
        # Apply the wallpaper to all monitors
        subprocess.run(
            ["hyprctl", "hyprpaper", "wallpaper", f",{str(selected_path)}"],
            stderr=subprocess.DEVNULL,
        )
    else:
        print("No wallpaper selected")


if __name__ == "__main__":
    wallpaper_picker()
