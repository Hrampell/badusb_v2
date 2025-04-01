#!/bin/bash
# This script uses macOS’s Core Location (via a temporary Swift script) to get your precise location,
# opens a map with your coordinates, sets your volume to maximum, speaks a message,
# and sends the information (timestamp, username, latitude, longitude, and message) to a Discord webhook.
#
# Requirements:
# - macOS
# - Xcode Command Line Tools (for Swift)
# - curl, osascript, say, and python3 (typically available by default)
#
# Usage:
#   ./location_script.sh "Your custom message here"
# If no message is provided, a default message is used.

# Write a temporary Swift script to get location using Core Location
swift_script=$(mktemp /tmp/getlocation.XXXX.swift)
cat << 'EOF' > "$swift_script"
#!/usr/bin/env swift
import Foundation
import CoreLocation

class LocationDelegate: NSObject, CLLocationManagerDelegate {
    var result: String?
    var locationManager: CLLocationManager!

    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func start() {
        // Request permission (this will prompt the user on first run)
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.first {
            // Output the latitude and longitude separated by a space
            result = "\(loc.coordinate.latitude) \(loc.coordinate.longitude)"
            locationManager.stopUpdatingLocation()
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        result = "error"
        CFRunLoopStop(CFRunLoopGetCurrent())
    }
}

let delegate = LocationDelegate()
delegate.start()
CFRunLoopRun()
if let res = delegate.result {
    print(res)
}
EOF

# Execute the Swift script and capture its output
location_data=$(swift "$swift_script")
rm "$swift_script"

# Parse the output: expect "latitude longitude"
lat=$(echo "$location_data" | awk '{print $1}')
lon=$(echo "$location_data" | awk '{print $2}')

if [ -z "$lat" ] || [ -z "$lon" ] || [ "$lat" = "error" ]; then
    echo "Failed to retrieve location
