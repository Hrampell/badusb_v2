#!/bin/bash
# JumpScare 2.0 – Debug Version for macOS
# This script downloads a jumpscare .mov video from GitHub, sets the system volume to maximum,
# and immediately plays the video in QuickTime Player in full-screen mode.
#
# Requirements:
# - macOS with curl, osascript, and QuickTime Player installed.
#
# Usage:
#   chmod +x JumpScare2.0.sh
#   ./JumpScare2.0.sh
#
# Debug information will be printed to help troubleshoot download issues.

# --- Configuration ---
JUMPSCARE_URL="https://raw.githubusercontent.com/Hrampell/badusb_v2/main/andrew_jumpscare.mov"
TEMP_VIDEO="/tmp/andrew_jumpscare.mov"
echo "JUMPSCARE_URL: $JUMPSCARE_URL"
echo "TEMP_VIDEO: $TEMP_VIDEO"

# --- Hide Terminal and display a "Loading..." notification ---
osascript -e 'tell application "Terminal" to set visible of front window to false'
osascript -e 'display notification "Loading JumpScare..." with title "JumpScare 2.0"'

# --- Debug: Check if the URL is reachable ---
echo "Checking HTTP headers for the video URL..."
curl -I "$JUMPSCARE_URL"

# --- Download the jumpscare video with verbose output ---
echo "Downloading jumpscare video..."
curl -v -sL "$JUMPSCARE_URL" -o "$TEMP_VIDEO"
curl_exit=$?
echo "curl exit code: $curl_exit"

# --- Verify download ---
if [ ! -f "$TEMP_VIDEO" ] || [ ! -s "$TEMP_VIDEO" ]; then
    echo "ERROR: Failed to download the jumpscare video."
    osascript -e 'display notification "Download failed." with title "JumpScare 2.0 Error"'
    exit 1
fi
echo "Video downloaded successfully to $TEMP_VIDEO."
echo "File size: $(stat -f%z "$TEMP_VIDEO") bytes"

# --- Set system volume to maximum ---
echo "Setting system volume to maximum..."
osascript -e 'set volume output volume 100'
echo "Volume set."

# --- Play the video in QuickTime Player in full screen ---
echo "Attempting to play video in QuickTime Player..."
osascript <<EOF
tell application "QuickTime Player"
    activate
    open POSIX file "$TEMP_VIDEO"
    delay 3
    try
        tell document 1
            set presenting to true
        end tell
    on error errMsg
        tell application "System Events" to keystroke "f" using {command down, control down}
    end try
end tell
EOF
echo "Command to play video issued."

echo "JumpScare2.0 Debug Script Completed."
