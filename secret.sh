#!/usr/bin/env ruby
require 'open-uri'
require 'thread'

# Daemonize the process so it detaches from the terminal.
# This ensures the background tasks continue running even after the terminal is closed.
Process.daemon

# Define the base URL and audio file location.
rick = "https://keroserene.net/lol"
audio_raw_url = "#{rick}/roll.s16"
audio_file = "/tmp/roll.s16"

# Download the audio file if it does not exist.
unless File.exist?(audio_file)
  File.open(audio_file, "wb") do |local_file|
    open(audio_raw_url) do |remote_file|
      local_file.write(remote_file.read)
    end
  end
end

# Method to set the system volume to maximum.
def adjust_volume
  if system("command -v osascript > /dev/null 2>&1")
    system("osascript -e 'set volume output volume 100'")
  elsif system("command -v amixer > /dev/null 2>&1")
    system("amixer set Master 100%")
  else
    # No supported volume control found.
  end
end

# Start a background thread to adjust volume every 3 seconds.
volume_thread = Thread.new do
  loop do
    adjust_volume
    sleep 3
  end
end

# Method to play one audio instance using an available audio player.
def play_audio_instance(audio_file)
  if system("command -v afplay > /dev/null 2>&1")
    Process.spawn("nohup afplay #{audio_file} >/dev/null 2>&1")
  elsif system("command -v aplay > /dev/null 2>&1")
    command = "cat #{audio_file} | aplay -Dplug:default -q -f S16_LE -r 8000"
    Process.spawn("nohup bash -c '#{command}' >/dev/null 2>&1")
  elsif system("command -v play > /dev/null 2>&1")
    Process.spawn("nohup play -q #{audio_file} >/dev/null 2>&1")
  else
    exit 1
  end
end

# Spawn 5 overlapping audio instances with a 5-second delay between each.
5.times do |i|
  play_audio_instance(audio_file)
  sleep 5
end

# Keep the script running indefinitely so the volume thread remains active.
volume_thread.join
