# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "typer",
# ]
# ///

import os
import subprocess
import typer
from pathlib import Path
from typing import Annotated

app = typer.Typer()

# Use absolute paths or expanduser
THEMES_DIR = Path(os.path.expanduser("~/.config/waybar/themes"))
THEME_SETTING = Path(os.path.expanduser("~/.config/waybar/current_theme"))
LAUNCH_SCRIPT = Path(os.path.expanduser("~/.config/waybar/launch.sh"))

@app.command()
def select():
    """
    List Waybar themes using Rofi and apply the selected one.
    """
    if not THEMES_DIR.exists():
        typer.echo(f":: Error: Themes directory {THEMES_DIR} not found.", err=True)
        return

    # List only directories that contain a 'config' file
    themes = []
    for d in THEMES_DIR.iterdir():
        if d.is_dir() and (d / "config").exists():
            themes.append(d.name)
    
    themes.sort()

    if not themes:
        typer.echo(":: Error: No themes found in " + str(THEMES_DIR), err=True)
        return

    # Run Rofi
    rofi_process = subprocess.run(
        ["rofi", "-dmenu", "-i", "-p", "Waybar Theme"],
        input="\n".join(themes),
        text=True,
        capture_output=True
    )

    selected_theme = rofi_process.stdout.strip()
    if not selected_theme:
        return

    if selected_theme in themes:
        # Save the selected theme
        THEME_SETTING.parent.mkdir(parents=True, exist_ok=True)
        with open(THEME_SETTING, "w") as f:
            f.write(selected_theme)
        
        typer.echo(f":: Applying theme: {selected_theme}")
        
        # Restart Waybar using the launch script
        if LAUNCH_SCRIPT.exists():
            subprocess.run([str(LAUNCH_SCRIPT)], check=True)
        else:
            # Fallback: kill waybar and let hyprland restart it if it's in a loop, 
            # or just try to run waybar directly if we knew the command.
            # But since we modified launch.sh, we should use it.
            typer.echo(f":: Warning: Launch script {LAUNCH_SCRIPT} not found. Restarting waybar manually...", err=True)
            subprocess.run(["killall", "waybar"])
            subprocess.run(["waybar", "-c", str(THEMES_DIR / selected_theme / "config"), "-s", str(THEMES_DIR / selected_theme / "style.css")], start_new_session=True)

if __name__ == "__main__":
    app()
