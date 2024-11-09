# #!/bin/bash
#
# # Get the list of profiles and their descriptions for card #2
# profiles=$(pactl list cards | awk '
# /^Card #2/,/^Card #[0-9]/ {
#     if ($1 == "Profiles:") p=1;
#     else if ($1 == "Active" || $1 == "Ports:") p=0;
#     else if (p && $0 ~ /^[ \t]+[^ \t]/) {
#         # Line is indented and contains a profile
#         # Remove leading whitespace
#         line = $0;
#         sub(/^[ \t]+/, "", line);
#         # Extract profile name and description
#         match(line, /^([^:]+):\s*(.*)$/, arr);
#         if (arr[1] && arr[2]) {
#             profile_name = arr[1];
#             description = arr[2];
#             print profile_name "\t" description;
#         }
#     }
# }
# ')
#
# # Check if any profiles were found
# if [ -z "$profiles" ]; then
#     echo "No profiles found for Card #2."
#     exit 1
# fi
#
# # Display the profiles in rofi with descriptions
# selected=$(echo "$profiles" | rofi -dmenu -i -p "Select Profile for Card #2:")
#
# # If a profile was selected
# if [ -n "$selected" ]; then
#     # Extract the profile name (the first field)
#     profile_name=$(echo "$selected" | cut -f1)
#     # Set the selected profile
#     pactl set-card-profile 2 "$profile_name"
# fi
#
