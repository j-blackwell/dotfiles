# /// script
# requires-python = ">=3.13"
# dependencies = [
# ]
# ///

import subprocess

if __name__ == "__main__":
    command = 'grim -g "$(slurp)" - | tesseract - - | wl-copy && notify-send --app-name "OCR Screenshot" "Text Copied" "Extracted text copied to clipboard!"'
    subprocess.run(["bash", "-c", command])
