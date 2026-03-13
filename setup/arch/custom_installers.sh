#!/bin/bash

echo ":: Running Custom Installers..."

# OpenCode
if ! command -v opencode &>/dev/null; then
	echo ":: Installing OpenCode..."
	curl -fsSL https://opencode.ai/install | bash
else
	echo ":: OpenCode is already installed."
fi

# Add other custom/curl-based installers here as needed
# Example:
# if ! command -v some-tool &> /dev/null; then
#    curl -sS https://example.com/install.sh | bash
# fi
