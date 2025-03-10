# /// script
# requires-python = ">=3.13"
# dependencies = []
# ///

import subprocess

actions = {
    f"{chr(0xF033E)} Lock Screen": "loginctl lock-session",
    f"{chr(0xF0343)} Logout": "loginctl terminate-session",
    f"{chr(0xF04B2)} Suspend": "systemctl suspend",
    f"{chr(0xF02CA)} Hibernate": "systemctl hibernate",
    f"{chr(0xF0709)} Reboot": "systemctl reboot",
    f"{chr(0xF0425)} Shutdown": "systemctl poweroff",
}


def system_action_picker():
    menu = "\n".join(actions.keys())

    result = subprocess.run(
        ["rofi", "-dmenu", "-i", "-p", "Select Action"],
        input=menu,
        text=True,
        capture_output=True,
    )

    selected_action = result.stdout.strip()

    if selected_action and selected_action in actions:
        command = actions[selected_action]
        subprocess.run(command, shell=True)
        print(f"Executing: {command}")
    else:
        print("No valid action selected")


if __name__ == "__main__":
    system_action_picker()
