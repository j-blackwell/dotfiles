#!/usr/bin/env python3
"""The owner's Google calendar for today and the next two days, fetched once and shared.

`calendar_agenda.py waybar` is waybar's custom/calendar module, run every 60 s: it refreshes
~/.cache/calendar/agenda.json with one gcalcli call and prints the bar's countdown JSON.
scratchnote.py reads the same file through load(), and fetches live only when it is stale
(e.g. waybar isn't running).
"""

import html
import json
import os
import re
import subprocess
import sys
from dataclasses import asdict, dataclass
from datetime import date, datetime, timedelta
from pathlib import Path

CACHE_DIR = Path.home() / ".cache/calendar"
AGENDA_FILE = CACHE_DIR / "agenda.json"
OWNER_FILE = CACHE_DIR / "owner"
DAYS = 3  # today plus two, so the bar can count down to the next working morning
MAX_AGE = timedelta(minutes=5)
ICON = ""


class CalendarError(Exception):
    pass


@dataclass
class Event:
    title: str
    start: datetime
    end: datetime
    all_day: bool
    attendees: list[str]  # display names, excluding the owner, rooms and groups


def gcalcli(*args: str, timeout: float) -> str:
    try:
        result = subprocess.run(
            ["gcalcli", "--nocolor", *args], capture_output=True, text=True, timeout=timeout
        )
    except subprocess.TimeoutExpired:
        raise CalendarError(f"gcalcli {args[0]} timed out after {timeout}s")
    except FileNotFoundError:
        raise CalendarError("gcalcli is not installed")
    if result.returncode != 0:
        err = result.stderr.strip()
        raise CalendarError(err.splitlines()[-1] if err else "gcalcli failed")
    return result.stdout


def owner_calendar(timeout: float) -> str:
    """The calendar the user owns, cached because `gcalcli list` costs a second."""
    if OWNER_FILE.exists() and (name := OWNER_FILE.read_text().strip()):
        return name
    for line in gcalcli("list", timeout=timeout).splitlines():
        parts = line.split()
        if len(parts) >= 2 and parts[0] == "owner":
            name = " ".join(parts[1:])
            CACHE_DIR.mkdir(parents=True, exist_ok=True)
            OWNER_FILE.write_text(name)
            return name
    raise CalendarError("no owned calendar found in `gcalcli list`")


def name_from_email(email: str) -> str:
    local = email.split("@")[0]
    return " ".join(part.capitalize() for part in re.split(r"[._-]+", local) if part)


# `gcalcli agenda --details end --details attendees` prints, per day:
#   Fri Nov 20  9:30  - 10:30  Kenneth / James      <- day header, sharing a line with the first event
#                     Attendees:
#                       Not Provided: <kenneth@...>  <- "Not Provided" when Google has no display name
#               12:30 - 13:30  Lunch
#   Tue Nov 17         Office                        <- all-day events have no times
DAY_HEADER = re.compile(r"^([A-Z][a-z]{2} [A-Z][a-z]{2} +\d{1,2})(?=\s)")
TIMED = re.compile(r"^\s+(\d{1,2}:\d{2})\s+-\s+(\d{1,2}:\d{2})\s+(.+?)\s*$")
ATTENDEE = re.compile(r"^\s+(.*?):\s+<([^>]+@[^>]+)>\s*$")


def parse_agenda(text: str, first_day: date, owner: str) -> list[Event]:
    events: dict[tuple, Event] = {}
    seen_emails: dict[tuple, set[str]] = {}
    day: date | None = None
    current: tuple | None = None
    for line in text.splitlines():
        if not line.strip():
            continue
        if match := DAY_HEADER.match(line):
            parsed = datetime.strptime(f"{match.group(1)} {first_day.year}", "%a %b %d %Y").date()
            day = parsed if parsed >= first_day else parsed.replace(year=first_day.year + 1)
            line = " " * len(match.group(1)) + line[match.end() :]
            if not line.strip():
                continue
        if day is None or line.strip() == "Attendees:":
            continue
        if match := ATTENDEE.match(line):
            if current is None:
                continue
            name, email = match.groups()
            skip = email.lower() == owner.lower() or "calendar.google.com" in email
            if not skip and email.lower() not in seen_emails[current]:
                seen_emails[current].add(email.lower())
                events[current].attendees.append(name if name != "Not Provided" else name_from_email(email))
            continue
        if match := TIMED.match(line):
            start_t, end_t, title = match.groups()
            start = datetime.combine(day, datetime.strptime(start_t, "%H:%M").time())
            end = datetime.combine(day, datetime.strptime(end_t, "%H:%M").time())
            if end <= start:  # runs past midnight
                end += timedelta(days=1)
            all_day = False
        else:
            title = line.strip()
            start = datetime.combine(day, datetime.min.time())
            end = start + timedelta(days=1)
            all_day = True
        # Recurring events shared across calendars can come back twice; merge them.
        current = (title, start, end)
        if current not in events:
            events[current] = Event(title, start, end, all_day, [])
            seen_emails[current] = set()
    return sorted(events.values(), key=lambda e: (e.start, not e.all_day))


def refresh(timeout: float) -> list[Event]:
    """Fetch the agenda from Google and rewrite the cache."""
    owner = owner_calendar(timeout)
    today = date.today()
    text = gcalcli(
        "--calendar", owner, "agenda", "--nodeclined", "--military",
        "--details", "end", "--details", "attendees",
        today.isoformat(), (today + timedelta(days=DAYS)).isoformat(),
        timeout=timeout,
    )
    events = parse_agenda(text, today, owner)
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    payload = {
        "fetched_at": datetime.now().isoformat(timespec="seconds"),
        "events": [
            {**asdict(e), "start": e.start.isoformat(), "end": e.end.isoformat()} for e in events
        ],
    }
    tmp = AGENDA_FILE.with_suffix(f".{os.getpid()}.tmp")
    tmp.write_text(json.dumps(payload, indent=1))
    tmp.replace(AGENDA_FILE)  # atomic, so a reader never sees half a file
    return events


def read_cache() -> tuple[datetime, list[Event]] | None:
    try:
        payload = json.loads(AGENDA_FILE.read_text())
        events = [
            Event(
                title=e["title"],
                start=datetime.fromisoformat(e["start"]),
                end=datetime.fromisoformat(e["end"]),
                all_day=e["all_day"],
                attendees=e["attendees"],
            )
            for e in payload["events"]
        ]
        return datetime.fromisoformat(payload["fetched_at"]), events
    except (OSError, ValueError, KeyError, TypeError):
        return None


def load(timeout: float, max_age: timedelta = MAX_AGE) -> list[Event]:
    """Cached events if fetched in the last `max_age`, otherwise a live fetch."""
    cached = read_cache()
    if cached and timedelta(0) <= datetime.now() - cached[0] <= max_age:
        return cached[1]
    return refresh(timeout)


def duration(delta: timedelta) -> str:
    minutes = int(delta.total_seconds()) // 60
    hours, minutes = divmod(minutes, 60)
    return f"{hours}h {minutes}m" if hours else f"{minutes}m"


def waybar() -> None:
    try:
        events = refresh(timeout=20)
        error = ""
    except CalendarError as e:
        cached = read_cache()
        events = cached[1] if cached else []
        error = f"Calendar refresh failed: {e}"

    now = datetime.now()
    upcoming = next((e for e in events if not e.all_day and e.start > now), None)
    text = f"{ICON}  {duration(upcoming.start - now)}: {upcoming.title}" if upcoming else ""

    # Waybar renders both strings as Pango markup.
    lines = [html.escape(error)] if error else []
    day = None
    for e in events:
        if e.end <= now:
            continue
        if e.start.date() != day:
            day = e.start.date()
            lines += [""] if lines else []
            lines.append(f"<b>{day:%a %d %b}</b>")
        when = "all day" if e.all_day else f"{e.start:%H:%M}–{e.end:%H:%M}"
        lines.append(f"  {when:<11}  {html.escape(e.title)}")
    tooltip = "\n".join(lines) or "No upcoming events"
    print(json.dumps({"text": html.escape(text), "tooltip": tooltip}))


if __name__ == "__main__":
    if sys.argv[1:] == ["waybar"]:
        waybar()
    else:
        sys.exit("usage: calendar_agenda.py waybar")
