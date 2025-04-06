#!/usr/bin/env ruby
require 'open-uri'

# Define URLs and local file path.
rick = "https://keroserene.net/lol"
audio_raw_url = "#{rick}/roll.s16"
audio_file = "/tmp/roll.s16"

# Download the audio file if it doesn't already exist.
unless File.exist?(audio_file)
  File.open(audio_file, "wb") do |f|
    f.write URI.open(audio_raw_url).read
  end
end

# Method to set system volume to maximum.
def adjust_volume
  if system("command -v osascript > /dev/null")
    # macOS: sets volume to 100 (max)
    system("osascript -e 'set volume output volume 100'")
  elsif system("command -v amixer > /dev/null")
    # Linux: sets Master volume to 100%
    system("amixer set Master 100%")
  else
    puts "Volume adjustment not supported on this system."
  end
end

# Start a thread to adjust volume every 3 seconds.
volume_thread = Thread.new do
  loop do
    adjust_volume
    sleep 3
  end
end

# Method to play one instance of the audio using a supported audio player.
def play_audio_instance(audio_file)
  if system("command -v afplay > /dev/null")
    Process.spawn("nohup afplay #{audio_file} >/dev/null 2>&1")
  elsif system("command -v aplay > /dev/null")
    Process.spawn("nohup aplay -Dplug:default -q -f S16_LE -r 8000 #{audio_file} >/dev/null 2>&1")
  elsif system("command -v play > /dev/null")
    Process.spawn("nohup play -q #{audio_file} >/dev/null 2>&1")
  else
    puts "No supported audio player found."
    exit 1
  end
end

# Overlay 5 audio instances with a 5-second delay between each.
5.times do
  play_audio_instance(audio_file)
  sleep 5
end

# Keep the script running indefinitely so the volume thread continues to work.
volume_thread.join