sudo cp com.apple.locate.custom.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/com.apple.locate.custom.plist
sudo chmod 644 /Library/LaunchDaemons/com.apple.locate.custom.plist
sudo launchctl bootout system/com.apple.locate 2>/dev/null || true
sudo launchctl bootstrap system /Library/LaunchDaemons/com.apple.locate.custom.plist
sudo launchctl kickstart system/com.apple.locate.custom
