# /// script
# requires-python = ">=3.13"
# ///
"""Scratch call note: a tmux-backed nvim buffer pre-filled with the current calendar event.

Run inside the `scratchnote` kitty window (SUPER+N in hyprland.lua). If the `scratchnote`
tmux session is still alive (e.g. the window was closed by accident) it reattaches to it.
Otherwise it reads today's events from the calendar cache that waybar refreshes every
minute (calendar_agenda.py, fetching live if that is stale). A meeting in progress is used
straight away; between meetings an fzf picker lists today's, closest first, plus a blank
note. The note itself lives only in nvim's memory until saved; see
nvim/.config/nvim/lua/custom/scratchnote.lua.
"""

import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

import calendar_agenda
from calendar_agenda import CalendarError, Event, duration

SESSION = "scratchnote"
NOTES_DIR = Path.home() / "code/notes/ember/calls"
RUNTIME_DIR = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "scratchnote"
CALENDAR_TIMEOUT = 5  # only hit when the cache is stale
MAX_ATTENDEES = 8


def notify(summary: str, body: str = "", urgency: str = "normal") -> None:
    subprocess.run(["notify-send", "-a", "Scratch note", "-u", urgency, summary, body], check=False)


def fmt(dt: datetime) -> str:
    return dt.strftime("%Y-%m-%d %H:%M")


def distance(event: Event, now: datetime) -> float:
    """How far `event` is from now: 0 while it runs, else the gap to its start or end."""
    if event.start > now:
        return (event.start - now).total_seconds()
    return max(0.0, (now - event.end).total_seconds())


def when(event: Event, now: datetime) -> str:
    if event.start > now:
        return f"in {duration(event.start - now)}"
    if event.end > now:
        return "now"
    return f"ended {duration(now - event.end)} ago"


def pick(events: list[Event], now: datetime) -> Event | None:
    """fzf over `events` plus a blank note; Esc also means a blank note."""
    rows = [
        f"{i}\t{e.start:%H:%M}–{e.end:%H:%M}  {e.title}  \x1b[2m{when(e, now)}\x1b[0m"
        for i, e in enumerate(events)
    ] + [f"{len(events)}\tBlank note"]
    result = subprocess.run(
        [
            "fzf", "--ansi", "--no-sort", "--layout=reverse", "--info=hidden",
            "--delimiter=\t", "--with-nth=2..",
            "--prompt=Which call? ", "--header=Enter to open · Esc for a blank note",
        ],
        input="\n".join(rows),
        stdout=subprocess.PIPE,
        text=True,
    )
    choice = result.stdout.split("\t", 1)[0]
    if not choice.isdigit() or int(choice) >= len(events):
        return None
    return events[int(choice)]


def find_event(now: datetime) -> Event | None:
    events = [
        e
        for e in calendar_agenda.load(timeout=CALENDAR_TIMEOUT)
        if not e.all_day and e.start.date() == now.date()
    ]
    in_progress = [e for e in events if e.start <= now < e.end]
    if len(in_progress) == 1:
        return in_progress[0]
    if not events:
        return None
    return pick(in_progress or sorted(events, key=lambda e: distance(e, now)), now)


def slugify(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")[:60].rstrip("-")


def header(event: Event | None, now: datetime) -> str:
    if event is None:
        return f"# Scratch {fmt(now)}\n\n"
    lines = [f"# {event.title}", f"{fmt(event.start)}–{event.end:%H:%M}"]
    if event.attendees:
        shown = ", ".join(event.attendees[:MAX_ATTENDEES])
        extra = len(event.attendees) - MAX_ATTENDEES
        lines.append(f"Attendees: {shown}" + (f" (+{extra} more)" if extra > 0 else ""))
    return "\n".join(lines) + "\n\n"


def tmux_session_exists() -> bool:
    return subprocess.run(["tmux", "has-session", "-t", f"={SESSION}"], capture_output=True).returncode == 0


def main() -> None:
    if tmux_session_exists():
        os.execvp("tmux", ["tmux", "attach-session", "-t", f"={SESSION}"])

    now = datetime.now()
    print("Looking for a relevant calendar event…", flush=True)
    try:
        event = find_event(now)
    except CalendarError as e:
        notify("Calendar lookup failed", f"{e}\nStarting a blank note.", urgency="critical")
        event = None

    name = now.strftime("%Y-%m-%dT%H%M")
    if event and (slug := slugify(event.title)):
        name += f"-{slug}"

    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    header_file = RUNTIME_DIR / "header.md"
    header_file.write_text(header(event, now))

    # <leader>nx writes the committed note's path here for scratchnote_actions.py.
    committed = RUNTIME_DIR / "committed"
    committed.unlink(missing_ok=True)

    env = {
        "SCRATCHNOTE": "1",
        "SCRATCHNOTE_NAME": name,
        "SCRATCHNOTE_DIR": str(NOTES_DIR),
        "SCRATCHNOTE_HEADER": str(header_file),
        "SCRATCHNOTE_EVENT": event.title if event else "",
        "SCRATCHNOTE_COMMITTED": str(committed),
    }
    tmux = ["tmux", "new-session", "-s", SESSION, "-c", str(NOTES_DIR.parent.parent)]
    for key, value in env.items():
        tmux += ["-e", f"{key}={value}"]
    # After nvim exits, extract actions from a committed note into Google Tasks.
    tmux += [
        "sh",
        "-c",
        "nvim -c \"lua require('custom.scratchnote').start()\"; "
        "exec ~/.local/bin/uv run --script ~/.local/bin/custom/scratchnote_actions.py",
    ]
    tmux += [";", "set-option", "-t", f"={SESSION}:", "status", "off"]
    sys.stdout.flush()
    os.execvp("tmux", tmux)


if __name__ == "__main__":
    main()
