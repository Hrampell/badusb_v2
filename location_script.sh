#!/bin/bash
# This script retrieves your geolocation, opens a map with your coordinates,
# sets your system volume to maximum, speaks a custom message (if provided),
# and sends the information (with a timestamp and username) to a Discord webhook.
#
# Requirements:
# - macOS
# - Homebrew installed (https://brew.sh)
# - CoreLocationCLI installed (this script will attempt to auto-install it if missing)
#
# Usage:
#   ./location_script.sh "Your custom message here"
# If no message is provided, a default message is used.

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
    echo "Homebrew is not installed. Please install Homebrew first."
    exit 1
fi

# Try to locate CoreLocationCLI in common Homebrew install paths.
if [ -x "/usr/local/bin/CoreLocationCLI" ]; then
    CLCOMMAND="/usr/local/bin/CoreLocationCLI"
elif [ -x "/opt/homebrew/bin/CoreLocationCLI" ]; then
    CLCOMMAND="/opt/homebrew/bin/CoreLocationCLI"
elif command -v CoreLocationCLI &>/dev/null; then
    CLCOMMAND=$(command -v CoreLocationCLI)
else
    CLCOMMAND=""
fi

# If not found, attempt to install it via Homebrew.
if [ -z "$CLCOMMAND" ]; then
    echo "CoreLocationCLI not found. Attempting to install it via Homebrew..."
    brew install corelocationcli
    if [ -x "/usr/local/bin/CoreLocationCLI" ]; then
        CLCOMMAND="/usr/local/bin/CoreLocationCLI"
    elif [ -x "/opt/homebrew/bin/CoreLocationCLI" ]; then
        CLCOMMAND="/opt/homebrew/bin/CoreLocationCLI"
    else
        CLCOMMAND=$(command -v CoreLocationCLI)
    fi
fi

if [ -z "$CLCOMMAND" ] || [ ! -x "$CLCOMMAND" ]; then
    echo "Failed to install CoreLocationCLI. Please install it manually using: brew install corelocationcli"
    exit 1
fi

# Retrieve geolocation using CoreLocationCLI
location_output=$("$CLCOMMAND")
latitude=$(echo "$location_output" | grep -i "latitude:" | awk '{print $2}' | tr -d ',')
longitude=$(echo "$location_output" | grep -i "longitude:" | awk '{print $2}')

# Get the current username for logging purposes
username=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

echo "Your location: Latitude $latitude, Longitude $longitude"

# Construct Google Maps URL and open it in the default browser
map_url="https://www.google.com/maps/search/?api=1&query=${latitude},${longitude}"
echo "Opening map: $map_url"
open "$map_url"

# Set system volume to maximum using AppleScript
osascript -e '
