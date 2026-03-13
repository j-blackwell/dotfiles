#!/bin/bash

# Check if the venv directory does not exist
if [ ! -d ./venv ]
then
    python3 -m venv ./venv
fi

source ./venv/bin/activate

# Check for the existence of .env file and source it if it exists
if [ -f ./.env ]
then
    echo "Loading environment variables from ./.env"
    while read -r line || [[ -n "$line" ]]
    do
        if [[ ! "$line" =~ ^# ]]
        then
            var_name=$(echo "$line" | cut -d '=' -f 1)
            echo -e "\t- $var_name"
            export "$line"
        fi
    done < ./.env
fi
