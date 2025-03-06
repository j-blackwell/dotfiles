# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "emoji",
#     "pyperclip",
# ]
# ///

import subprocess
import pyperclip
import emoji


def emoji_picker():
    print(dir(emoji))
    emoji_dict = {name["en"]: symbol for symbol, name in emoji.EMOJI_DATA.items()}
    emoji_menu = "\n".join(f"{symbol} {name}" for name, symbol in emoji_dict.items())

    result = subprocess.run(
        ["rofi", "-dmenu", "-p", "Pick an emoji"],
        input=emoji_menu,
        text=True,
        capture_output=True,
    )
    selected_line = result.stdout.strip()

    if selected_line:
        selected_emoji = selected_line.split()[0]
        pyperclip.copy(selected_emoji)
        print(f"Copied to clipboard: {selected_emoji}")
    else:
        print("No emoji selected")


if __name__ == "__main__":
    emoji_picker()
