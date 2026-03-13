#!/bin/bash

# Detect OS
if [ -f /etc/arch-release ]; then
	echo ":: Arch Linux detected."
	bash "$(dirname "$0")/arch/main.sh"
else
	echo ":: Error: This setup suite currently only supports Arch Linux."
	exit 1
fi
