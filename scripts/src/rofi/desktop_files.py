# /// script
# requires-python = ">=3.13"
# dependencies = []
# ///

import shlex
import subprocess
from pathlib import Path


def desktop_file_editor():
    desktop_dir = Path("/usr/share/applications")
    desktop_files = [f.name for f in desktop_dir.glob("*.desktop")]

    result = subprocess.run(
        ["rofi", "-dmenu", "-i", "-p", "Select .desktop file"],
        input="\n".join(desktop_files),
        text=True,
        capture_output=True,
    )

    selected_file = result.stdout.strip()

    if selected_file and selected_file in desktop_files:
        subprocess.run(
            [
                "kitty",
                "--directory",
                str(desktop_dir),
                "sh",
                "-c",
                f"sudo vim {shlex.quote(str(desktop_dir/selected_file))}; exec $SHELL",
            ]
        )
    else:
        print("No valid action selected")


if __name__ == "__main__":
    desktop_file_editor()
