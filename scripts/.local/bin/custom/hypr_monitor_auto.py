import socket
import subprocess
import os
import time

def hyprctl(command):
    subprocess.run(["hyprctl", "keyword"] + command.split(), check=False)

def apply_docked():
    print("Applying Docked Profile")
    hyprctl("monitor DP-2,3440x1440@100,0x0,1")
    hyprctl("monitor eDP-1,disable")

def apply_undocked():
    print("Applying Undocked Profile")
    hyprctl("monitor eDP-1,preferred,auto,1")

def event_loop():
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", "/run/user/1000")
    socket_path = f"{runtime_dir}/hypr/{signature}/.socket2.sock"

    # Initial setup
    try:
        monitors = subprocess.check_output(["hyprctl", "monitors", "all"], text=True)
        if "DP-2" in monitors:
            apply_docked()
        else:
            apply_undocked()
    except Exception as e:
        print(f"Initial setup failed: {e}")

    # Start listening to events
    try:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.connect(socket_path)
    except Exception as e:
        print(f"Failed to connect to socket: {e}")
        return

    while True:
        try:
            data = client.recv(1024).decode('utf-8')
            if not data: break
            for line in data.split('\n'):
                if "monitoradded>>DP-2" in line:
                    time.sleep(1) # Wait for monitor to settle
                    apply_docked()
                elif "monitorremoved>>DP-2" in line:
                    apply_undocked()
        except Exception as e:
            print(f"Error in event loop: {e}")
            break

if __name__ == "__main__":
    event_loop()
