# /// script
# requires-python = ">=3.13"
# dependencies = []
# ///

import os
import subprocess
from pathlib import Path


def code_projects():
    directories = []
    base_dirs = ["~/code", "~/code-personal", "~/dotfiles/nvim/.config"]

    for base in base_dirs:
        base_path = Path(base).expanduser()
        if base_path.exists() and base_path.is_dir():
            base_sub_dirs = [d.name for d in base_path.iterdir() if d.is_dir()]
            directories += base_sub_dirs

    directories.append("dotfiles")
    return directories


def get_terminal():
    terminal_setting = Path("~/dotfiles/.config/ml4w/settings/terminal.sh")
    with open(terminal_setting.expanduser(), "r") as f:
        data = f.read().strip()

    return data


def main():
    projects = "\n".join(code_projects())
    result = subprocess.run(
        ["rofi", "-dmenu", "-p", "Select code project"],
        input=projects,
        text=True,
        capture_output=True,
    )
    code_project = result.stdout.strip()

    if not code_project:
        print("Cancel")
        return

    base_dirs = ["~/code", "~/code-personal", "~/dotfiles/nvim/.config"]
    full_path = None

    for base in base_dirs:
        base_path = Path(base).expanduser() / code_project
        if base_path.exists() and base_path.is_dir():
            full_path = str(base_path)
            break

    if not full_path:
        full_path = Path("~/dotfiles").expanduser()

    subprocess.Popen(
        [
            get_terminal(),
            "tmux",
            "new-session",
            "-A",
            "-s",
            code_project,
            "zsh",
            "-c",
            f"cd {full_path} && nvim .; zsh",
        ]
    )


if __name__ == "__main__":
    main()
