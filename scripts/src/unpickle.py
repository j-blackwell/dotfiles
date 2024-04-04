# nano ~/.bashrc
# alias unpickle="python3 ~/code/bash/unpickle.py"

import argparse
import pickle


parser = argparse.ArgumentParser(
    description="Unpickle a file",
    formatter_class=argparse.ArgumentDefaultsHelpFormatter
)
parser.add_argument("file", help="Path of the file to unpickle")

args = vars(parser.parse_args())

try:

    with open(args["file"], "rb") as p:
        data = pickle.load(p)

    print(type(data))
    print(data)

except TypeError:
    print("No file parameter supplied. Use an argument to supply the path of the file to unpickle")

except FileNotFoundError:
    print(f"File with name '{args['file']}' not found.")
