# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "typer",
# ]
# ///

import subprocess

import typer

app = typer.Typer()


@app.command()
def copy():
    command = 'grim -g "$(slurp)" - | tee >(wl-copy) && notify-send --app-name "Screenshot" "Screenshot" "Screenshot copied to clipboard!"'
    subprocess.run(["bash", "-c", command])


@app.command()
def swappy():
    command = 'grim -g "$(slurp)" - | swappy -f -'
    subprocess.run(["bash", "-c", command])


if __name__ == "__main__":
    app()
