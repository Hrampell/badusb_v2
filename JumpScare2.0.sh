#!/bin/bash
# JumpScare 2.0 – Mac Version (Immediate Execution)
# This script downloads a jumpscare .mov video from GitHub, 
# sets the system volume to maximum, and immediately plays the video in QuickTime Player in full-screen.
#
# Requirements:
# - macOS with curl, osascript, and QuickTime Player installed.
#
# Usage:
#   chmod +x JumpScare2.0.sh
#   ./JumpScare2.0.sh

# --- Configuration ---
# Raw URL of the jumpscare .mov file (update if necessary)
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

# --- Immediately set system volume to maximum ---
osascript -e 'set volume output volume 100'

# --- Immediately play the video in QuickTime Player in full-screen ---
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

# Optional: Clean up the temporary video file after playback
# rm "$TEMP_VIDEO"
