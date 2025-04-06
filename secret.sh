#!/usr/bin/env perl
use strict;
use warnings;
use LWP::Simple;
use File::Which;
use POSIX ":sys_wait_h";

# Define URLs and file path.
my $rick         = "https://keroserene.net/lol";
my $audio_raw_url = "$rick/roll.s16";
my $audio_file    = "/tmp/roll.s16";

# Array to store child process IDs.
my @child_pids;

# Download the audio file if it doesn't exist.
unless ( -e $audio_file ) {
    print "Downloading audio from $audio_raw_url...\n";
    my $status = getstore($audio_raw_url, $audio_file);
    die "Error downloading audio, status: $status\n" if $status != 200;
    print "Download complete.\n";
}

# Function to set system volume to maximum.
sub adjust_volume {
    if ( which("osascript") ) {
        system("osascript -e 'set volume output volume 100' >/dev/null 2>&1");
    }
    elsif ( which("amixer") ) {
        system("amixer set Master 100% >/dev/null 2>&1");
    }
    else {
        print "No supported volume control found.\n";
    }
}

# Start a child process that continuously sets the volume every 3 seconds.
my $vol_pid = fork();
die "Fork failed for volume loop\n" unless defined $vol_pid;
if ( $vol_pid == 0 ) {
    # Child process: volume loop.
    while (1) {
        adjust_volume();
        sleep 3;
    }
    exit 0;
}
else {
    push @child_pids, $vol_pid;
}

# Function to play a single audio instance.
sub play_audio_instance {
    my $pid = fork();
    die "Fork failed for audio instance\n" unless defined $pid;
    if ( $pid == 0 ) {
        # Child: redirect output and execute the audio player.
        open STDOUT, '>', '/dev/null' or die "Can't redirect STDOUT: $!";
        open STDERR, '>', '/dev/null' or die "Can't redirect STDERR: $!";
        if ( which("afplay") ) {
            exec("afplay", $audio_file);
        }
        elsif ( which("aplay") ) {
            exec("bash", "-c", "cat $audio_file | aplay -Dplug:default -q -f S16_LE -r 8000");
        }
        elsif ( which("play") ) {
            exec("play", "-q", $audio_file);
        }
        else {
            die "No supported audio player found.\n";
        }
        exit 0;
    }
    else {
        return $pid;
    }
}

# Spawn 5 overlapping audio instances with a 5-second delay between each.
my @audio_pids;
for my $i ( 1 .. 5 ) {
    my $pid = play_audio_instance();
    push @audio_pids, $pid if $pid;
    sleep 5;
}
push @child_pids, @audio_pids;

# SIGINT handler to clean up child processes on CTRL+C.
$SIG{INT} = sub {
    print "\nCaught SIGINT. Terminating child processes...\n";
    kill 'KILL', $_ for @child_pids;
    exit 0;
};

# Keep the script running indefinitely.
while (1) {
    sleep 1;
}
