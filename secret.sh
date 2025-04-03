#!/bin/bash
# Rick Astley in your Terminal (modified).
version='1.2-mod'
rick='https://keroserene.net/lol'
video="$rick/astley80.full.bz2"
audio_gsm="$rick/roll.gsm"
audio_raw="$rick/roll.s16"

audpid=0
stop_audio=0

# Check if a command exists.
has?() { hash "$1" 2>/dev/null; }

# Cleanup function to kill background processes.
cleanup() {
  [ "$audpid" -gt 0 ] && kill "$audpid" 2>/dev/null
  [ -n "$volpid" ] && kill "$volpid" 2>/dev/null
  [ -n "$monpid" ] && kill "$monpid" 2>/dev/null
}
trap "cleanup" INT
trap "exit" EXIT

# Function to obtain data from a URL.
obtainium() {
  if has? curl; then
    curl -s "$1"
  elif has? wget; then
    wget -q -O - "$1"
  else
    echo "No internet command available." && exit 1
  fi
}

# Clear the screen.
echo -en "\033[2J\033[H"

# Pre-fetch the audio file if needed (for afplay on macOS).
if has? afplay; then
  [ -f /tmp/roll.s16 ] || obtainium "$audio_raw" > /tmp/roll.s16
fi

# Function to force system volume to maximum.
adjust_volume() {
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "set volume output volume 100" >/dev/null 2>&1
  elif command -v amixer >/dev/null 2>&1; then
    amixer set Master 100% >/dev/null 2>&1
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
      [ "$audpid" -gt 0 ] && kill "$audpid" 2>/dev/null
      break
    fi
  done
}
monitor_stop &
monpid=$!

# Function to play audio 5 times.
play_audio() {
  for ((i=1; i<=5; i++)); do
    [ "$stop_audio" -eq 1 ] && break
    if has? afplay; then
      afplay /tmp/roll.s16 &
      audpid=$!
      wait "$audpid"
    elif has? aplay; then
      obtainium "$audio_raw" | aplay -Dplug:default -q -f S16_LE -r 8000 &
      audpid=$!
      wait "$audpid"
    elif has? play; then
      obtainium "$audio_gsm" > /tmp/roll.gsm.wav
      play -q /tmp/roll.gsm.wav &
      audpid=$!
      wait "$audpid"
    fi
  done
}
play_audio

# ASCII video playback (unchanged).
python <(cat <<'EOF'
import sys
import time
fps = 25
time_per_frame = 1.0 / fps
buf = ''
frame = 0
next_frame = 0
begin = time.time()
try:
    for i, line in enumerate(sys.stdin):
        if i % 32 == 0:
            frame += 1
            sys.stdout.write(buf)
            buf = ''
            elapsed = time.time() - begin
            repose = (frame * time_per_frame) - elapsed
            if repose > 0.0:
                time.sleep(repose)
            next_frame = elapsed / time_per_frame
        if frame >= next_frame:
            buf += line
except KeyboardInterrupt:
    pass
EOF
) < <(obtainium "$video" | bunzip2 -q 2> /dev/null)
