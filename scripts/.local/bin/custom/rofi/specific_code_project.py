# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "typer",
# ]
# ///

import os
import subprocess
from pathlib import Path

import typer


def get_terminal():
    terminal_setting = Path("~/.config/hypr/settings/terminal.sh")
    with open(terminal_setting.expanduser(), "r") as f:
        data = f.read().strip()

    return data


def tmux_command(name: str, path: str) -> list[str]:
    """Attach to the tmux session, or create it with an nvim window and a claude window.

    The session is created from inside the terminal (not detached beforehand) so
    nvim starts at the terminal's real size rather than tmux's 80x24 default.
    """
    exists = subprocess.run(
        ["tmux", "has-session", "-t", f"={name}"], capture_output=True
    ).returncode == 0
    if exists:
        return ["tmux", "attach-session", "-t", f"={name}"]

    return [
        "tmux",
        "new-session", "-s", name, "-c", path,
        "zsh -ic 'nvim .; exec zsh'",
        ";",
        "new-window", "-d", "-t", f"={name}:", "-c", path,
        "zsh -ic 'claude; exec zsh'",
    ]


def open_project(code_project: str):
    if not code_project:
        print("No project set")
        return

    tmux_name = Path(code_project).name

    subprocess.Popen([get_terminal(), *tmux_command(tmux_name, str(code_project))])


app = typer.Typer()


@app.command()
def main(code_project: str):
    open_project(code_project)


if __name__ == "__main__":
    app()
