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
            # Get the first image in the gallery
            first_item = list(metadata.values())[0]
            image_url = first_item.get("s", {}).get("u")
    else:
        image_url = post_data.get("url")

    if image_url:
        return image_url.replace("&amp;", "&")
    return None

def get_thumbnail_url(post_data: Dict) -> Optional[str]:
    # Try to get a decent resolution preview
    preview = post_data.get("preview", {}).get("images", [])
    if preview:
        resolutions = preview[0].get("resolutions", [])
        if resolutions:
            # Pick a middle resolution (around 640px wide if possible)
            idx = min(len(resolutions) - 1, 3) 
            return resolutions[idx].get("url").replace("&amp;", "&")
    
    # Fallback to thumbnail if it's a URL
    thumb = post_data.get("thumbnail")
    if thumb and thumb.startswith("http"):
        return thumb.replace("&amp;", "&")
        
    # Gallery fallback
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
    if os.path.exists(dest_path):
        return True
    headers = {"User-Agent": USER_AGENT}
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        with open(dest_path, "wb") as f:
            f.write(response.content)
        return True
    except Exception:
        return False

def set_wallpaper_hyprland(file_path: str):
    try:
        # Preload the image (necessary for hyprpaper)
        subprocess.run(["hyprctl", "hyprpaper", "preload", file_path], capture_output=True)
        # Set the wallpaper
        subprocess.run(["hyprctl", "hyprpaper", "wallpaper", f",{file_path}"], check=True)
    except subprocess.CalledProcessError as e:
        typer.echo(f":: Error: Failed to set wallpaper using hyprctl: {e}", err=True)

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
    date_file = os.path.join(directory, f"{today}.jpg")
    current_file = os.path.join(directory, "current.jpg")

    if not force and os.path.exists(date_file):
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
            if download_file(url, date_file):
                shutil.copy2(date_file, current_file)
                set_wallpaper_hyprland(current_file)
                return

    typer.echo(":: Error: No suitable wallpaper found.", err=True)
    raise typer.Exit(code=1)

@app.command()
def select(
    subreddit: Annotated[str, typer.Option(help="Subreddit to fetch from")] = "WidescreenWallpaper",
    directory: Annotated[str, typer.Option(help="Directory to save wallpapers")] = os.path.expanduser("~/Pictures/reddit_wallpaper"),
    exclude: Annotated[str, typer.Option(help="Regex of keywords to exclude")] = r"dump|32:9|ai|vehicles|anime|meme|gaming|abstract",
):
    """
    Select a wallpaper from the top reddit posts using Rofi with previews.
    """
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
            valid_posts.append({
                "title": title, 
                "url": url, 
                "thumb_url": thumb_url, 
                "id": post_id, 
                "thumb_path": thumb_path
            })

    if not valid_posts:
        typer.echo(":: Error: No valid posts found.", err=True)
        return

    # Parallel download thumbnails
    typer.echo(":: Fetching previews...")
    with ThreadPoolExecutor(max_workers=10) as executor:
        executor.map(lambda p: download_file(p["thumb_url"], p["thumb_path"]), valid_posts)

    # Prepare Rofi menu entries
    menu_entries = []
    for p in valid_posts:
        if os.path.exists(p["thumb_path"]):
            menu_entries.append(f"{p['title']}\0icon\x1f{p['thumb_path']}")
        else:
            menu_entries.append(p["title"])

    menu_input = "\n".join(menu_entries)
    
    rofi_process = subprocess.run(
        [
            "rofi", "-dmenu", "-i", 
            "-p", f"Select from r/{subreddit}", 
            "-show-icons",
            "-theme-str", ROFI_PREVIEW_THEME
        ],
        input=menu_input,
        text=True,
        capture_output=True
    )

    selected_line = rofi_process.stdout.strip()
    if not selected_line:
        return

    # Find the selected post
    selected_post = next((p for p in valid_posts if p["title"] == selected_line), None)
    if not selected_post:
        return

    # Download and set
    filename = f"{datetime.date.today().strftime('%Y-%m-%d')}_{selected_post['id']}.jpg"
    dest_path = os.path.join(directory, filename)
    current_file = os.path.join(directory, "current.jpg")

    if download_file(selected_post["url"], dest_path):
        shutil.copy2(dest_path, current_file)
        set_wallpaper_hyprland(current_file)

@app.command()
def local(
    directory: Annotated[str, typer.Option(help="Directory to pick wallpapers from")] = os.path.expanduser("~/Pictures/reddit_wallpaper"),
):
    """
    Pick a wallpaper from locally downloaded files.
    """
    wallpaper_dir = Path(directory)
    if not wallpaper_dir.exists():
        typer.echo(f":: Error: Directory {directory} does not exist.", err=True)
        return

    # Create entries with icon metadata for Rofi
    entries = []
    # Only include actual images, excluding current.jpg and .cache
    for x in sorted(wallpaper_dir.glob("*.jpg"), reverse=True):
        if x.name == "current.jpg":
            continue
        entries.append(f"{x.name}\0icon\x1f{x.absolute()}")

    if not entries:
        typer.echo(":: No local wallpapers found.", err=True)
        return

    wallpaper_menu = "\n".join(entries)

    result = subprocess.run(
        [
            "rofi", "-dmenu", "-i", 
            "-p", "Local Wallpapers", 
            "-show-icons",
            "-theme-str", ROFI_PREVIEW_THEME
        ],
        input=wallpaper_menu,
        text=True,
        capture_output=True,
    )
    
    selected_line = result.stdout.strip()
    if not selected_line:
        return

    selected_path = (wallpaper_dir / selected_line).resolve()
    current_file = wallpaper_dir / "current.jpg"

    if selected_path.exists():
        shutil.copy2(str(selected_path), str(current_file))
        set_wallpaper_hyprland(str(current_file))

if __name__ == "__main__":
    app()
