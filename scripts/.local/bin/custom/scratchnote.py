# /// script
# requires-python = ">=3.13"
# ///
"""Scratch call note: a tmux-backed nvim buffer pre-filled with the current calendar event.

Run inside the `scratchnote` kitty window (SUPER+N in hyprland.lua). If the `scratchnote`
tmux session is still alive (e.g. the window was closed by accident) it reattaches to it.
Otherwise it looks up the relevant event on the owner's Google calendar via gcalcli:
the one in progress, else one starting within 15 minutes, else the one that ended
most recently. Several candidates means a rofi pick. The note itself lives only in
nvim's memory until saved; see nvim/.config/nvim/lua/custom/scratchnote.lua.
"""

import os
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path

SESSION = "scratchnote"
NOTES_DIR = Path.home() / "code/notes/ember/calls"
CACHE_DIR = Path.home() / ".cache/scratchnote"
RUNTIME_DIR = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "scratchnote"
GCALCLI_TIMEOUT = 3
UPCOMING_WINDOW = timedelta(minutes=15)
MAX_ATTENDEES = 8


class CalendarError(Exception):
    pass


@dataclass
class Event:
    title: str
    start: datetime
    end: datetime
    attendees: list[str]


def notify(summary: str, body: str = "", urgency: str = "normal") -> None:
    subprocess.run(["notify-send", "-a", "Scratch note", "-u", urgency, summary, body], check=False)


def gcalcli(*args: str) -> str:
    try:
        result = subprocess.run(
            ["gcalcli", "--nocolor", *args],
            capture_output=True,
            text=True,
            timeout=GCALCLI_TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        raise CalendarError(f"gcalcli {args[0]} timed out after {GCALCLI_TIMEOUT}s")
    except FileNotFoundError:
        raise CalendarError("gcalcli is not installed")
    if result.returncode != 0:
        raise CalendarError(result.stderr.strip().splitlines()[-1] if result.stderr.strip() else "gcalcli failed")
    return result.stdout


def owner_calendar() -> str:
    """The calendar the user owns, cached because `gcalcli list` costs a second."""
    cache = CACHE_DIR / "calendar"
    if cache.exists() and (name := cache.read_text().strip()):
        return name
    for line in gcalcli("list").splitlines():
        parts = line.split()
        if len(parts) >= 2 and parts[0] == "owner":
            name = " ".join(parts[1:])
            CACHE_DIR.mkdir(parents=True, exist_ok=True)
            cache.write_text(name)
            return name
    raise CalendarError("no owned calendar found in `gcalcli list`")


def fmt(dt: datetime) -> str:
    return dt.strftime("%Y-%m-%d %H:%M")


def todays_events(calendar: str, now: datetime) -> list[Event]:
    start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    out = gcalcli(
        "--calendar", calendar, "agenda", "--tsv", "--nodeclined", fmt(start), fmt(now + UPCOMING_WINDOW)
    )
    events = []
    for line in out.splitlines()[1:]:
        cols = line.split("\t")
        if len(cols) < 5 or not cols[1]:  # all-day events have no start time
            continue
        start_date, start_time, end_date, end_time, title = cols[:5]
        events.append(
            Event(
                title=title,
                start=datetime.strptime(f"{start_date} {start_time}", "%Y-%m-%d %H:%M"),
                end=datetime.strptime(f"{end_date} {end_time}", "%Y-%m-%d %H:%M"),
                attendees=[],
            )
        )
    # Recurring events shared across calendars can come back twice.
    unique = {(e.title, e.start, e.end): e for e in events}
    return list(unique.values())


def candidates(events: list[Event], now: datetime) -> list[Event]:
    in_progress = [e for e in events if e.start <= now < e.end]
    if in_progress:
        return in_progress
    upcoming = [e for e in events if now < e.start <= now + UPCOMING_WINDOW]
    if upcoming:
        return upcoming
    ended = [e for e in events if e.end <= now]
    if not ended:
        return []
    latest_end = max(e.end for e in ended)
    return [e for e in ended if e.end == latest_end]


def pick(events: list[Event]) -> Event | None:
    if len(events) <= 1:
        return events[0] if events else None
    options = [f"{e.start:%H:%M}–{e.end:%H:%M}  {e.title}" for e in events] + ["none"]
    result = subprocess.run(
        ["rofi", "-dmenu", "-i", "-p", "Which call?", "-format", "i"],
        input="\n".join(options),
        capture_output=True,
        text=True,
    )
    choice = result.stdout.strip()
    if not choice.isdigit() or int(choice) >= len(events):
        return None
    return events[int(choice)]


def name_from_email(email: str) -> str:
    local = email.split("@")[0]
    return " ".join(part.capitalize() for part in re.split(r"[._-]+", local) if part)


def attendees(calendar: str, event: Event) -> list[str]:
    """Attendee names for `event`. The TSV output has no attendees, so parse the text agenda."""
    out = gcalcli(
        "--calendar",
        calendar,
        "agenda",
        "--nodeclined",
        "--details",
        "attendees",
        fmt(event.start),
        fmt(event.start + timedelta(minutes=1)),
    )
    emails: list[str] = []
    in_event = False
    for line in out.splitlines():
        if re.search(r"\d{1,2}:\d{2}\s+\S", line):  # an event's time + title line
            in_event = line.rstrip().endswith(event.title)
            continue
        if in_event and (match := re.search(r"<([^>]+@[^>]+)>", line)):
            emails.append(match.group(1))
    me = calendar.lower()
    people = []
    for email in dict.fromkeys(emails):  # dedupe, keep order
        if email.lower() == me or "resource.calendar.google.com" in email or "group.calendar" in email:
            continue
        people.append(name_from_email(email))
    return people


def find_event(now: datetime) -> Event | None:
    calendar = owner_calendar()
    event = pick(candidates(todays_events(calendar, now), now))
    if event:
        event.attendees = attendees(calendar, event)
    return event


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

    env = {
        "SCRATCHNOTE": "1",
        "SCRATCHNOTE_NAME": name,
        "SCRATCHNOTE_DIR": str(NOTES_DIR),
        "SCRATCHNOTE_HEADER": str(header_file),
    }
    tmux = ["tmux", "new-session", "-s", SESSION, "-c", str(NOTES_DIR.parent.parent)]
    for key, value in env.items():
        tmux += ["-e", f"{key}={value}"]
    tmux += ["nvim", "-c", "lua require('custom.scratchnote').start()"]
    tmux += [";", "set-option", "-t", f"={SESSION}:", "status", "off"]
    sys.stdout.flush()
    os.execvp("tmux", tmux)


if __name__ == "__main__":
    main()
