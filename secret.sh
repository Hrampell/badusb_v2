#!/usr/bin/env python2
import os
import sys
import time
import subprocess
import threading
import urllib2
from distutils.spawn import find_executable

# Define DEVNULL equivalent for Python 2.
DEVNULL = open(os.devnull, 'wb')

def download_audio(audio_raw_url, audio_file):
    if not os.path.exists(audio_file):
        try:
            print "Downloading audio from {} ...".format(audio_raw_url)
            response = urllib2.urlopen(audio_raw_url)
            data = response.read()
            response.close()
            with open(audio_file, 'wb') as f:
                f.write(data)
            print "Download complete."
        except Exception as e:
            print "Error downloading audio:", e
            sys.exit(1)

def which(cmd):
    return find_executable(cmd)

def adjust_volume():
    # For macOS: set volume to maximum using osascript.
    if which("osascript"):
        subprocess.call(["osascript", "-e", "set volume output volume 100"],
                        stdout=DEVNULL, stderr=DEVNULL)
    # For Linux: set Master volume to 100% using amixer.
    elif which("amixer"):
        subprocess.call(["amixer", "set", "Master", "100%"],
                        stdout=DEVNULL, stderr=DEVNULL)
    else:
        print "No supported volume control found."

def volume_loop(stop_event):
    while not stop_event.is_set():
        adjust_volume()
        time.sleep(3)

def play_audio_instance(audio_file):
    # Try macOS afplay first.
    if which("afplay"):
        return subprocess.Popen(["nohup", "afplay", audio_file],
                                stdout=DEVNULL, stderr=DEVNULL)
    elif which("aplay"):
        command = "cat {} | aplay -Dplug:default -q -f S16_LE -r 8000".format(audio_file)
        return subprocess.Popen(["nohup", "bash", "-c", command],
                                stdout=DEVNULL, stderr=DEVNULL)
    elif which("play"):
        return subprocess.Popen(["nohup", "play", "-q", audio_file],
                                stdout=DEVNULL, stderr=DEVNULL)
    else:
        print "No supported audio player found."
        sys.exit(1)

def main():
    rick = "https://keroserene.net/lol"
    audio_raw_url = "{}/roll.s16".format(rick)
    audio_file = "/tmp/roll.s16"

    # Download the audio file if it does not exist.
    download_audio(audio_raw_url, audio_file)

    # Start the volume-setting thread.
    stop_event = threading.Event()
    vol_thread = threading.Thread(target=volume_loop, args=(stop_event,))
    vol_thread.setDaemon(True)
    vol_thread.start()

    # Launch 5 overlapping audio instances with a 5-second delay between each.
    processes = []
    for i in range(5):
        print "Starting audio instance {}...".format(i + 1)
        proc = play_audio_instance(audio_file)
        processes.append(proc)
        time.sleep(5)

    # Keep the script running indefinitely.
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print "Stopping audio processes and volume thread..."
        stop_event.set()
        for proc in processes:
            proc.kill()
        sys.exit(0)

if __name__ == "__main__":
    main()
