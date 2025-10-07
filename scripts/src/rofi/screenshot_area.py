# /// script
# requires-python = ">=3.13"
# dependencies = [
# ]
# ///

import subprocess

if __name__ == "__main__":
    command = 'grim -g "$(slurp)" - | tee >(wl-copy) | swappy -f -'
    subprocess.run(["bash", "-c", command])
