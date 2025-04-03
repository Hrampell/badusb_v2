#!/bin/bash
# Rick Astley in your Terminal (modified for testing and detached audio)
version='1.2-test-detached'
rick='https://keroserene.net/lol'
video="$rick/astley80.full.bz2"
audio_gsm="$rick/roll.gsm"
audio_raw="$rick/roll.s16"

audpids=()
stop_audio=0

# Check if a command exists.
has() { command -v "$1" >/dev/null 2>&1; }

# Function to obtain data from a URL.
obtainium() {
  if has curl; then
    curl -s "$1"
  elif has wget; then
    wget -q -O - "$1"
  else
    echo "No internet command available." && exit 1
  fi
}

# Clear the screen.
echo -en "\033[2J\033[H"

# Pre-fetch the audio file if needed (for afplay on macOS).
if has afplay; then
  [ -f /tmp/roll.s16 ] || obtainium "$audio_raw" > /tmp/roll.s16
fi

# Function to set volume to 3 (for testing purposes).
adjust_volume() {
  if has osascript; then
    osascript -e "set volume output volume 3" >/dev/null 2>&1
  elif has amixer; then
    amixer set Master 3% >/dev/null 2>&1
  fi
}

# Background loop to adjust volume every 3 seconds.
volume_loop() {
  while [ "$stop_audio" -eq 0 ]; do
    adjust_volume
    sleep 3
  done
}
volume_loop &
volpid=$!

# Background monitor to watch for "sydneysweeny" typed in the terminal.
monitor_stop() {
  while read -r line < /dev/tty; do
    if [ "$line" = "sydneysweeny" ]; then
      stop_audio=1
      for pid in "${audpids[@]}"; do
        kill "$pid" 2>/dev/null
      done
      break
    fi
  done
}
monitor_stop &
monpid=$!

# Function to play a single audio instance in detached mode.
play_single_audio() {
  if has afplay; then
    nohup afplay /tmp/roll.s16 >/dev/null 2>&1 &
    audpids+=($!)
  elif has aplay; then
    nohup bash -c "obtainium '$audio_raw' | aplay -Dplug:default -q -f S16_LE -r 8000" >/dev/null 2>&1 &
    audpids+=($!)
  elif has play; then
    obtainium "$audio_gsm" > /tmp/roll.gsm.wav
    nohup play -q /tmp/roll.gsm.wav >/dev/null 2>&1 &
    audpids+=($!)
  fi
}

# Overlay 5 audio instances with a 5-second delay between each.
for ((i=1; i<=5; i++)); do
  [ "$stop_audio" -eq 1 ] && break
  play_single_audio
  sleep 5
done

# The script exits here; the detached audio processes will continue running if the terminal is closed.
