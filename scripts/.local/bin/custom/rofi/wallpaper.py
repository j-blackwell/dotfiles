# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "requests",
#     "typer",
#     "wallhaven",
#     "typing_extensions",
# ]
# ///

import os
import datetime
import subprocess
import shutil
import time
from pathlib import Path
from typing import Annotated, Optional
import typer
import requests
from concurrent.futures import ThreadPoolExecutor
from wallhaven.api import Wallhaven

app = typer.Typer()

USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"

# Wallhaven tag ID 37 is "nature". Plain keyword search (q=nature) is fuzzy and can
# match wallpapers that don't actually carry the tag, so we require it by ID instead
# (q=id:<id>, the only exact-match form Wallhaven's search supports).
WALLHAVEN_NATURE_TAG_ID = 37

# Default Rofi theme for previews
ROFI_PREVIEW_THEME = (
    "element { orientation: vertical; } "
    "element-icon { size: 10em; } "
    "element-text { horizontal-align: 0.5; } "
    "listview { columns: 4; lines: 2; } "
    "window { width: 1000px; }"
)

def setup_directory(directory: str):
    os.makedirs(directory, exist_ok=True)

def get_hyprland_signature() -> Optional[str]:
    """Find the active Hyprland instance signature."""
    # 1. Try to get signature from a running hyprpaper or hyprland process
    for proc_name in ["hyprpaper", "Hyprland"]:
        try:
            pid = subprocess.check_output(["pgrep", "-x", proc_name]).decode().strip().split('\n')[0]
            with open(f"/proc/{pid}/environ", "rb") as f:
                environ = f.read().split(b'\0')
                for env_var in environ:
                    if env_var.startswith(b"HYPRLAND_INSTANCE_SIGNATURE="):
                        return env_var.decode().split("=")[1]
        except (subprocess.CalledProcessError, IndexError, FileNotFoundError):
            continue

    # 2. Fallback to filesystem discovery
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    hypr_dir = Path(runtime_dir) / "hypr"
    
    if hypr_dir.exists():
        instances = []
        for d in hypr_dir.glob("*"):
            if d.is_dir() and ((d / ".hyprpaper.sock").exists() or (d / "hyprland.log").exists()):
                instances.append(d)
        
        if instances:
            instances.sort(key=lambda x: x.stat().st_mtime, reverse=True)
            return instances[0].name
            
    return os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")

def download_file(url: str, dest_path: str):
    headers = {"User-Agent": USER_AGENT}
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        
        # Check actual content type to determine extension
        content = response.content
        extension = ".jpg"
        if content.startswith(b"\x89PNG"):
            extension = ".png"
        elif content.startswith(b"GIF8"):
            extension = ".gif"
        
        # Adjust dest_path if needed
        base_path = os.path.splitext(dest_path)[0]
        final_path = base_path + extension
        
        with open(final_path, "wb") as f:
            f.write(content)
        return final_path
    except Exception:
        return None

def build_wallhaven_client(categories: str, ratio: Optional[str], tag_id: int) -> Wallhaven:
    wh = Wallhaven()
    wh.params["sorting"] = "random"
    wh.params["categories"] = categories
    wh.params["purity"] = "100"  # SFW only
    if ratio:
        wh.params["ratios"] = ratio
    wh.params["q"] = f"id:{tag_id}"

    return wh

def set_wallpaper_hyprland(file_path: str):
    signature = get_hyprland_signature()
    env = os.environ.copy()
    if signature:
        env["HYPRLAND_INSTANCE_SIGNATURE"] = signature

    try:
        subprocess.run(["pgrep", "-x", "hyprpaper"], check=True, capture_output=True)
    except subprocess.CalledProcessError:
        typer.echo(":: Starting hyprpaper...")
        subprocess.Popen(["hyprpaper"], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(30):
            if signature:
                socket_path = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")) / "hypr" / signature / ".hyprpaper.sock"
                if socket_path.exists():
                    break
            time.sleep(0.1)

    try:
        # Create current.png for other tools
        current_png = os.path.join(os.path.dirname(file_path), "current.png")
        if os.path.abspath(file_path) != os.path.abspath(current_png):
            subprocess.run(["magick", file_path, current_png], check=True)

        # Preload wallpaper (ignore errors if already preloaded)
        subprocess.run(["hyprctl", "hyprpaper", "preload", file_path], env=env, capture_output=True)
        
        # Set wallpaper
        result = subprocess.run(["hyprctl", "hyprpaper", "wallpaper", f",{file_path}"], env=env, capture_output=True, text=True)
        if result.returncode != 0:
            typer.echo(f":: Error setting wallpaper: {result.stderr.strip()}", err=True)
        
        # Execute matugen with the same environment (to ensure hyprctl reload works)
        matugen_cmd = [os.path.expanduser("~/.cargo/bin/matugen"), "image", file_path]
        subprocess.run(matugen_cmd, env=env, check=True)
    except Exception as e:
        typer.echo(f":: Unexpected Error: {e}", err=True)

@app.command()
def fetch(
    categories: Annotated[str, typer.Option(help="Categories (general, anime, people) as binary (e.g. 110)")] = "100",
    ratio: Annotated[str, typer.Option(help="Aspect ratio (e.g. 21x9)")] = "21x9",
    directory: Annotated[str, typer.Option(help="Directory to save wallpapers")] = os.path.expanduser("~/Pictures/wallpapers"),
    tag_id: Annotated[int, typer.Option(help="Wallhaven tag ID that must be present (37 = nature)")] = WALLHAVEN_NATURE_TAG_ID,
    force: Annotated[bool, typer.Option("--force", "-f", help="Force download even if already downloaded today")] = False
):
    """
    Automatically fetch and set the top wallpaper from Wallhaven.
    """
    setup_directory(directory)

    today = datetime.date.today().strftime("%Y-%m-%d")
    current_file_base = os.path.join(directory, "current")

    # Try to find existing current file with any image extension
    current_file = None
    for ext in [".jpg", ".png"]:
        if os.path.exists(current_file_base + ext):
            current_file = current_file_base + ext
            break

    if not force and current_file and os.path.exists(os.path.join(directory, f"{today}{os.path.splitext(current_file)[1]}")):
        set_wallpaper_hyprland(current_file)
        return

    wh = build_wallhaven_client(categories, ratio, tag_id)
    results = wh.search()
    url = results.data[0].path if results.data else None

    if url:
        date_file_placeholder = os.path.join(directory, f"{today}.jpg")
        downloaded_path = download_file(url, date_file_placeholder)
        if downloaded_path:
            ext = os.path.splitext(downloaded_path)[1]
            # Clean up old current files
            for old_ext in [".jpg", ".png"]:
                try: os.remove(current_file_base + old_ext)
                except FileNotFoundError: pass
            
            new_current = current_file_base + ext
            shutil.copy2(downloaded_path, new_current)
            set_wallpaper_hyprland(new_current)
            return

    typer.echo(":: Error: No suitable wallpaper found.", err=True)
    raise typer.Exit(code=1)

@app.command()
def select(
    categories: Annotated[str, typer.Option(help="Categories")] = "100",
    ratio: Annotated[str, typer.Option(help="Aspect ratio (e.g. 21x9)")] = "21x9",
    directory: Annotated[str, typer.Option(help="Directory to save wallpapers")] = os.path.expanduser("~/Pictures/wallpapers"),
    tag_id: Annotated[int, typer.Option(help="Wallhaven tag ID that must be present (37 = nature)")] = WALLHAVEN_NATURE_TAG_ID,
):
    """
    Select a wallpaper from Wallhaven via Rofi.
    """
    setup_directory(directory)
    cache_dir = os.path.join(directory, ".cache")
    os.makedirs(cache_dir, exist_ok=True)

    wh = build_wallhaven_client(categories, ratio, tag_id)
    results = wh.search()

    valid_items = []
    for wallpaper in results.data:
        url = wallpaper.path
        thumb_url = wallpaper.thumbs.get("large") or wallpaper.thumbs.get("small") or url
        item_id = wallpaper.id
        title = f"ID: {item_id} ({wallpaper.resolution})"
        thumb_path = os.path.join(cache_dir, f"{item_id}.jpg")
        valid_items.append({
            "title": title,
            "url": url,
            "thumb_url": thumb_url,
            "id": item_id,
            "thumb_path": thumb_path
        })

    if not valid_items:
        typer.echo(":: Error: No wallpapers found.", err=True)
        return

    typer.echo(":: Fetching previews from wallhaven...")
    with ThreadPoolExecutor(max_workers=10) as executor:
        executor.map(lambda p: download_file(p["thumb_url"], p["thumb_path"]), valid_items)

    menu_entries = []
    for p in valid_items:
        icon_path = None
        for ext in [".jpg", ".png"]:
            p_path = os.path.join(cache_dir, f"{p['id']}{ext}")
            if os.path.exists(p_path):
                icon_path = p_path
                break
        
        if icon_path:
            menu_entries.append(f"{p['title']}\0icon\x1f{icon_path}")
        else:
            menu_entries.append(p["title"])

    rofi_process = subprocess.run(
        ["rofi", "-dmenu", "-i", "-p", "Select from wallhaven", "-show-icons", "-theme-str", ROFI_PREVIEW_THEME],
        input="\n".join(menu_entries), text=True, capture_output=True
    )

    selected_line = rofi_process.stdout.strip()
    if not selected_line: return
    selected_wp = next((p for p in valid_items if p["title"] == selected_line), None)
    if not selected_wp: return

    filename_base = f"{datetime.date.today().strftime('%Y-%m-%d')}_{selected_wp['id']}"
    current_file_base = os.path.join(directory, "current")
    
    downloaded_path = download_file(selected_wp["url"], os.path.join(directory, filename_base + ".jpg"))
    if downloaded_path:
        ext = os.path.splitext(downloaded_path)[1]
        for old_ext in [".jpg", ".png"]:
            try: os.remove(current_file_base + old_ext)
            except FileNotFoundError: pass
        new_current = current_file_base + ext
        shutil.copy2(downloaded_path, new_current)
        set_wallpaper_hyprland(new_current)

@app.command()
def local(
    directory: Annotated[str, typer.Option(help="Directory to pick wallpapers from")] = os.path.expanduser("~/Pictures/wallpapers"),
):
    """
    Select a locally stored wallpaper via Rofi.
    """
    wallpaper_dir = Path(directory)
    if not wallpaper_dir.exists():
        typer.echo(f":: Error: Directory {directory} does not exist.", err=True)
        return

    entries = []
    for x in sorted(list(wallpaper_dir.glob("*.jpg")) + list(wallpaper_dir.glob("*.png")), reverse=True):
        if x.stem == "current": continue
        entries.append(f"{x.name}\0icon\x1f{x.absolute()}")

    if not entries:
        typer.echo(":: No local wallpapers found.", err=True)
        return

    result = subprocess.run(
        ["rofi", "-dmenu", "-i", "-p", "Local Wallpapers", "-show-icons", "-theme-str", ROFI_PREVIEW_THEME],
        input="\n".join(entries), text=True, capture_output=True,
    )
    
    selected_line = result.stdout.strip()
    if not selected_line: return
    selected_path = (wallpaper_dir / selected_line).resolve()
    
    if selected_path.exists():
        ext = selected_path.suffix
        current_file_base = os.path.join(directory, "current")
        for old_ext in [".jpg", ".png"]:
            try: os.remove(current_file_base + old_ext)
            except FileNotFoundError: pass
        new_current = current_file_base + ext
        shutil.copy2(str(selected_path), new_current)
        set_wallpaper_hyprland(new_current)

if __name__ == "__main__":
    app()
