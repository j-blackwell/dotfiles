# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "requests",
#     "typer",
# ]
# ///

import os
import datetime
import requests
import subprocess
import sys
import re
import shutil
import time
from pathlib import Path
from typing import Annotated, List, Dict, Optional
import typer
from concurrent.futures import ThreadPoolExecutor

app = typer.Typer()

USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"

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

def get_reddit_posts(subreddit: str, limit: int = 25) -> List[Dict]:
    headers = {"User-Agent": USER_AGENT}
    url = f"https://www.reddit.com/r/{subreddit}/hot/.json?t=day&limit={limit}"
    
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json().get("data", {}).get("children", [])
    except Exception as e:
        typer.echo(f":: Error: Failed to fetch Reddit JSON: {e}", err=True)
        return []

def get_image_url_from_post(post_data: Dict) -> Optional[str]:
    image_url = None
    if post_data.get("is_gallery"):
        metadata = post_data.get("media_metadata", {})
        if metadata:
            first_item = list(metadata.values())[0]
            image_url = first_item.get("s", {}).get("u")
    else:
        image_url = post_data.get("url")

    if image_url:
        return image_url.replace("&amp;", "&")
    return None

def get_thumbnail_url(post_data: Dict) -> Optional[str]:
    preview = post_data.get("preview", {}).get("images", [])
    if preview:
        resolutions = preview[0].get("resolutions", [])
        if resolutions:
            idx = min(len(resolutions) - 1, 3) 
            return resolutions[idx].get("url").replace("&amp;", "&")
    
    thumb = post_data.get("thumbnail")
    if thumb and thumb.startswith("http"):
        return thumb.replace("&amp;", "&")
        
    if post_data.get("is_gallery"):
        metadata = post_data.get("media_metadata", {})
        if metadata:
            first_item = list(metadata.values())[0]
            previews = first_item.get("p", [])
            if previews:
                idx = min(len(previews) - 1, 3)
                return previews[idx].get("u").replace("&amp;", "&")
    
    return None

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
    subreddit: Annotated[str, typer.Option(help="Subreddit to fetch from")] = "WidescreenWallpaper",
    directory: Annotated[str, typer.Option(help="Directory to save wallpapers")] = os.path.expanduser("~/Pictures/reddit_wallpaper"),
    exclude: Annotated[str, typer.Option(help="Regex of keywords to exclude")] = r"dump|32:9|ai|vehicles|anime|meme|gaming|abstract",
    force: Annotated[bool, typer.Option("--force", "-f", help="Force download even if already downloaded today")] = False
):
    """
    Automatically fetch and set the top wallpaper from a subreddit.
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

    posts = get_reddit_posts(subreddit)
    exclude_pattern = re.compile(exclude, re.IGNORECASE)

    for post in posts:
        post_data = post.get("data", {})
        title = post_data.get("title", "").lower()
        flair = (post_data.get("link_flair_text") or "").lower()

        if exclude_pattern.search(title) or (flair and exclude_pattern.search(flair)):
            continue

        url = get_image_url_from_post(post_data)
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
    subreddit: Annotated[str, typer.Option(help="Subreddit to fetch from")] = "WidescreenWallpaper",
    directory: Annotated[str, typer.Option(help="Directory to save wallpapers")] = os.path.expanduser("~/Pictures/reddit_wallpaper"),
    exclude: Annotated[str, typer.Option(help="Regex of keywords to exclude")] = r"dump|32:9|ai|vehicles|anime|meme|gaming|abstract",
):
    setup_directory(directory)
    cache_dir = os.path.join(directory, ".cache")
    os.makedirs(cache_dir, exist_ok=True)

    posts = get_reddit_posts(subreddit, limit=30)
    exclude_pattern = re.compile(exclude, re.IGNORECASE)

    valid_posts = []
    for post in posts:
        data = post.get("data", {})
        title = data.get("title", "")
        flair = (data.get("link_flair_text") or "")
        if exclude_pattern.search(title) or (flair and exclude_pattern.search(flair)):
            continue
        url = get_image_url_from_post(data)
        if url:
            thumb_url = get_thumbnail_url(data) or url
            post_id = data.get("id")
            thumb_path = os.path.join(cache_dir, f"{post_id}.jpg")
            valid_posts.append({"title": title, "url": url, "thumb_url": thumb_url, "id": post_id, "thumb_path": thumb_path})

    if not valid_posts:
        typer.echo(":: Error: No valid posts found.", err=True)
        return

    typer.echo(":: Fetching previews...")
    with ThreadPoolExecutor(max_workers=10) as executor:
        executor.map(lambda p: download_file(p["thumb_url"], p["thumb_path"]), valid_posts)

    menu_entries = []
    for p in valid_posts:
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
        ["rofi", "-dmenu", "-i", "-p", f"Select from r/{subreddit}", "-show-icons", "-theme-str", ROFI_PREVIEW_THEME],
        input="\n".join(menu_entries), text=True, capture_output=True
    )

    selected_line = rofi_process.stdout.strip()
    if not selected_line: return
    selected_post = next((p for p in valid_posts if p["title"] == selected_line), None)
    if not selected_post: return

    filename_base = f"{datetime.date.today().strftime('%Y-%m-%d')}_{selected_post['id']}"
    current_file_base = os.path.join(directory, "current")
    
    downloaded_path = download_file(selected_post["url"], os.path.join(directory, filename_base + ".jpg"))
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
    directory: Annotated[str, typer.Option(help="Directory to pick wallpapers from")] = os.path.expanduser("~/Pictures/reddit_wallpaper"),
):
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
