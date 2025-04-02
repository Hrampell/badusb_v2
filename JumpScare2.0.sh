#!/bin/bash
# JumpScare 2.0 – Mac Version
# This script downloads a jumpscare .mov video from GitHub, waits for mouse movement,
# sets system volume to maximum, and then plays the video in QuickTime Player in full-screen.
#
# Requirements:
# - macOS with curl, osascript, and QuickTime Player installed.
#
# Usage:
#   chmod +x JumpScare2.0.sh
#   ./JumpScare2.0.sh

# --- Configuration ---
# Raw URL of the jumpscare .mov file
JUMPSCARE_URL="https://raw.githubusercontent.com/Hrampell/badusb_v2/main/andrew_jumpscare.mov"
# Temporary location for the downloaded video
TEMP_VIDEO="/tmp/andrew_jumpscare.mov"

# --- Hide Terminal and display a "Loading..." notification ---
osascript -e 'tell application "Terminal" to set visible of front window to false'
osascript -e 'display notification "Loading JumpScare..." with title "JumpScare 2.0"'

# --- Download the jumpscare video ---
echo "Downloading jumpscare video from $JUMPSCARE_URL..."
curl -sL "$JUMPSCARE_URL" -o "$TEMP_VIDEO"

if [ ! -f "$TEMP_VIDEO" ] || [ ! -s "$TEMP_VIDEO" ]; then
    echo "Failed to download the jumpscare video."
    osascript -e 'display notification "Download failed." with title "JumpScare 2.0 Error"'
    exit 1
fi
echo "Video downloaded to $TEMP_VIDEO."

# --- Wait for Mouse Movement ---
echo "Waiting for mouse movement..."
oldMouse=$(osascript -e 'tell application "System Events" to get the mouse location')
while true; do
    newMouse=$(osascript -e 'tell application "System Events" to get the mouse location')
    if [ "$newMouse" != "$oldMouse" ]; then
        break
    fi
    sleep 1
done
echo "Mouse movement detected."

# --- Set system volume to maximum ---
osascript -e 'set volume output volume 100'

# --- Play the video in QuickTime Player in full screen ---
# We open the video, wait a moment for QuickTime Player to load it, then activate full-screen.
osascript <<EOF
tell application "QuickTime Player"
    activate
    open POSIX file "$TEMP_VIDEO"
    delay 2
    tell document 1
        set presenting to true
    end tell
end tell
EOF

echo "Jumpscare video should now be playing in full screen."

# Note: Uncomment the next line if you wish to remove the downloaded video after playing.
# rm "$TEMP_VIDEO"
