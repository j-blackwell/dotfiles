# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "typer",
# ]
# ///

import os
import subprocess
import typer
from pathlib import Path


def get_terminal():
    terminal_setting = Path("~/dotfiles/.config/ml4w/settings/terminal.sh")
    with open(terminal_setting.expanduser(), "r") as f:
        data = f.read().strip()

    return data


def open_project(code_project: str):
    if not code_project:
        print("No project set")
        return

    tmux_name = Path(code_project).name

    subprocess.Popen(
        [
            get_terminal(),
            "tmux",
            "new-session",
            "-A",
            "-s",
            tmux_name,
            "bash",
            "-c",
            f"cd {code_project} && nvim .; bash",
        ]
    )


app = typer.Typer()


@app.command()
def main(code_project: str):
    open_project(code_project)


if __name__ == "__main__":
    app()
