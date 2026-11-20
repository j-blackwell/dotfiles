# /// script
# requires-python = ">=3.13"
# ///
"""Turn a committed scratch call note's action items into Google Tasks.

Runs in the scratch note's tmux pane after nvim exits (see scratchnote.py). Does nothing
unless <leader>nc committed a note, in which case nvim wrote its path to
$SCRATCHNOTE_COMMITTED. Claude (Haiku, via `claude -p`) extracts the actions, an fzf
checklist picks which to keep, and gws adds them to the default Google Tasks list.
Tasks that fail to add are kept in pending-tasks.md, opened here for editing and
retried on the next run.
"""

import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

PENDING = Path.home() / ".cache/scratchnote/pending-tasks.md"
MODEL = "claude-haiku-5-5"
CLAUDE_TIMEOUT = 60
GWS_TIMEOUT = 15

SCHEMA = {
    "type": "object",
    "properties": {
        "actions": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "title": {"type": "string"},
                    "due": {"type": ["string", "null"], "description": "YYYY-MM-DD, or null"},
                },
                "required": ["title", "due"],
            },
        }
    },
    "required": ["actions"],
}

PROMPT = """\
Extract the action items from these call notes, written by {me} during a call on {date:%A %Y-%m-%d}.
- {me}'s own actions: short imperative task titles, e.g. "Send Neha the Q3 numbers".
- Actions owned by someone else: "Follow up: <Name> – <action>".
- Skip discussion points, things {me} only wanted to say, and musings that aren't commitments.
- due: YYYY-MM-DD only when a deadline is stated ("by Friday", "tomorrow"), resolved against the
  call date; otherwise null.
The notes are on stdin."""

# Hyprland-launched shells may not have ~/.local/bin (claude, gws) on PATH.
os.environ["PATH"] = f"{Path.home() / '.local/bin'}:{os.environ.get('PATH', '')}"


def notify(summary: str, body: str = "", urgency: str = "normal") -> None:
    subprocess.run(["notify-send", "-a", "Scratch note", "-u", urgency, summary, body], check=False)


def first_name() -> str:
    name = subprocess.run(["git", "config", "user.name"], capture_output=True, text=True).stdout.split()
    return name[0] if name else "the note's author"


def extract(note: str, call_date: datetime) -> list[dict]:
    result = subprocess.run(
        [
            "claude", "-p", PROMPT.format(me=first_name(), date=call_date),
            "--model", MODEL,
            "--tools", "",
            "--setting-sources", "",
            "--strict-mcp-config",
            "--no-session-persistence",
            "--output-format", "json",
            "--json-schema", json.dumps(SCHEMA),
        ],
        input=note,
        capture_output=True,
        text=True,
        timeout=CLAUDE_TIMEOUT,
        cwd=Path.home(),
    )
    out = json.loads(result.stdout or "{}")
    if result.returncode != 0 or out.get("is_error") or "structured_output" not in out:
        raise RuntimeError(out.get("result") or result.stderr.strip() or "claude -p failed")
    return out["structured_output"]["actions"]


def github_url(path: Path) -> str:
    def git(*args: str) -> str:
        return subprocess.run(["git", "-C", str(path.parent), *args], capture_output=True, text=True).stdout.strip()

    remote = git("remote", "get-url", "origin")
    repo = re.sub(r"^git@github\.com:|^https://github\.com/|\.git$", "", remote)
    relative = path.relative_to(git("rev-parse", "--show-toplevel"))
    return f"https://github.com/{repo}/blob/{git('branch', '--show-current')}/{relative}"


def label(task: dict) -> str:
    if not task.get("due"):
        return task["title"]
    return f"{task['title']}  (due {datetime.strptime(task['due'], '%Y-%m-%d'):%a %d %b})"


def choose(tasks: list[dict]) -> list[dict]:
    """fzf checklist with every action ticked: Tab unticks, Enter adds the ticked ones."""
    rows = [f"{i}\t{label(t)}" for i, t in enumerate(tasks)]
    result = subprocess.run(
        [
            "fzf", "--multi", "--no-sort", "--layout=reverse", "--info=hidden",
            "--delimiter=\t", "--with-nth=2..", "--bind=load:select-all",
            "--marker=☑ ", "--prompt=Add to Google Tasks: ",
            "--header=Tab to (un)tick · Enter to add ticked · Esc for none",
        ],
        input="\n".join(rows),
        stdout=subprocess.PIPE,
        text=True,
    )
    picked = {int(line.split("\t", 1)[0]) for line in result.stdout.splitlines() if line[:1].isdigit()}
    return [t for i, t in enumerate(tasks) if i in picked]


def add_task(task: dict) -> bool:
    body = {"title": task["title"], "notes": task.get("notes", "")}
    if task.get("due"):
        body["due"] = f"{task['due']}T00:00:00.000Z"
    try:
        result = subprocess.run(
            ["gws", "tasks", "tasks", "insert", "--params", '{"tasklist": "@default"}', "--json", json.dumps(body)],
            capture_output=True,
            text=True,
            timeout=GWS_TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        return False
    return result.returncode == 0


# pending-tasks.md lines: "- [ ] <title> | due <YYYY-MM-DD> | <notes>", notes with "\n" as " · ".
def read_pending() -> list[dict]:
    if not PENDING.exists():
        return []
    tasks = []
    for line in PENDING.read_text().splitlines():
        if not line.startswith("- [ ] "):
            continue
        title, due, notes = (line[6:].split(" | ") + ["", ""])[:3]
        tasks.append({
            "title": title.strip(),
            "due": due.removeprefix("due ").strip() or None,
            "notes": notes.strip().replace(" · ", "\n"),
        })
    return tasks


def write_pending(tasks: list[dict]) -> None:
    if not tasks:
        PENDING.unlink(missing_ok=True)
        return
    PENDING.parent.mkdir(parents=True, exist_ok=True)
    lines = ["<!-- Scratch note tasks not yet in Google Tasks; retried on the next <leader>nc. -->"]
    for t in tasks:
        due = f"due {t['due']}" if t.get("due") else ""
        lines.append(f"- [ ] {t['title']} | {due} | {t.get('notes', '').replace(chr(10), ' · ')}")
    PENDING.write_text("\n".join(lines) + "\n")


def main() -> None:
    marker = Path(os.environ.get("SCRATCHNOTE_COMMITTED", ""))
    if not marker.is_file():
        return
    note_path = Path(marker.read_text().strip())
    marker.unlink()

    print("Finding actions…", flush=True)
    event = os.environ.get("SCRATCHNOTE_EVENT") or "scratch note"
    call_date = datetime.strptime(note_path.name[:15], "%Y-%m-%dT%H%M")
    chosen: list[dict] = []
    try:
        actions = extract(note_path.read_text(), call_date)
    except Exception as e:  # noqa: BLE001 - any failure here should only notify
        notify("Finding actions failed", str(e)[:300], urgency="critical")
    else:
        if actions:
            chosen = choose(actions)
            notes = f"From: {event}\n{github_url(note_path)}"
            for t in chosen:
                t["notes"] = notes
        else:
            notify("No actions found", event)

    # Earlier failures are retried first.
    to_add = read_pending() + chosen
    failed = [t for t in to_add if not add_task(t)]
    write_pending(failed)
    added = [t for t in to_add if t not in failed]
    if added:
        notify(
            f"Added {len(added)} task{'s' if len(added) != 1 else ''} to Google Tasks",
            "\n".join(t["title"] for t in added),
        )
    if failed:
        notify("Some tasks weren't added", "\n".join(t["title"] for t in failed), urgency="critical")
        os.execvp("nvim", ["nvim", str(PENDING)])


if __name__ == "__main__":
    sys.exit(main())
