# /// script
# requires-python = ">=3.13"
# dependencies = []
# ///

import os
import subprocess
from pathlib import Path


def code_projects():
    directories = []
    base_dirs = ["~/code", "~/code-personal", "~/.config/nvim"]

    for base in base_dirs:
        base_path = Path(base).expanduser()
        if base_path.exists() and base_path.is_dir():
            base_sub_dirs = [d.name for d in base_path.iterdir() if d.is_dir()]
            directories += base_sub_dirs

    directories.append("dotfiles")
    return directories


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

    base_dirs = ["~/code", "~/code-personal", "~/.config/nvim"]
    full_path = None

    for base in base_dirs:
        base_path = Path(base).expanduser() / code_project
        if base_path.exists() and base_path.is_dir():
            full_path = str(base_path)
            break

    if not full_path:
        full_path = Path("~/dotfiles").expanduser()

    subprocess.Popen([get_terminal(), *tmux_command(code_project, str(full_path))])


if __name__ == "__main__":
    main()
