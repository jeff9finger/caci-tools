# macOS Troubleshooting Guide

Common issues and solutions for macOS system configuration in CACI environments.

## mailto: Links Not Opening Microsoft Outlook

### Symptom
After setting Microsoft Outlook as the default mail application in System Settings, clicking mailto: links still opens Apple Mail instead of Outlook.

### Root Cause
macOS uses the LaunchServices framework to manage URL protocol handlers. The System Settings UI updates a general preference but may not update the specific `mailto:` URL scheme handler. Additionally, the LaunchServices database caches old handler registrations.

### Solution for Unmanaged Macs

If your Mac is **not managed** by enterprise MDM/Configuration Profiles:

```bash
# Set Outlook as mailto: handler
defaults write ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerURLScheme=mailto;LSHandlerRoleAll=com.microsoft.Outlook;}'

# Restart UI services
killall Finder && killall Dock

# Test
open "mailto:test@example.com"
```

**Verify it worked:**
```bash
defaults read ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers | grep -A 2 mailto
```

Should show:
```
LSHandlerRoleAll = "com.microsoft.Outlook";
LSHandlerURLScheme = mailto;
```

**Alternative method using duti:**
```bash
brew install duti
duti -s com.microsoft.Outlook mailto all
```

Note: `duti` may fail with error -50 on some macOS versions. Use the `defaults` method above if this happens.

### Limitation: Enterprise Managed Macs

**If you get an error about "profile restrictions"**, your Mac is managed by CACI IT via MDM/Configuration Profiles.

Configuration Profiles enforce system policies and **override all user preferences**. There is no user-level workaround.

**Check if your Mac is managed:**
```bash
profiles list
```

If profiles are listed, especially ones from CACI IT, your Mac is managed.

**What to do:**
1. Contact CACI IT/Help Desk
2. Request they modify the Configuration Profile to allow Outlook as mailto: handler
3. Provide technical details:
   - Application: Microsoft Outlook
   - Bundle ID: `com.microsoft.Outlook`
   - URL Scheme: `mailto:`
   - Reason: Need Outlook for Exchange/Microsoft 365 integration

**Workaround:**
- Manually copy email addresses from links
- Paste into Outlook compose window

### Reverting Changes

To remove custom mailto: handler and restore defaults:

```bash
defaults delete ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers
killall Finder && killall Dock
```

## KeePassXC Integration Issues

See main README.md sections:
- **iterm-keepass-helper.sh** - iTerm2 password manager integration
- **refresh-token.sh** - Automated token refresh using KeePassXC

## LaunchServices Database Issues

### Symptoms
- File associations not working correctly
- URL schemes opening wrong applications
- Recently installed apps not appearing in "Open With" menu

### Solution: Rebuild LaunchServices Database

**Note:** Apple removed the `-kill` flag in recent macOS versions. The database rebuilds automatically, but you can force refresh by restarting services:

```bash
# Restart Finder and Dock (triggers rebuild)
killall Finder && killall Dock

# Log out and log back in (full refresh)
# Or reboot the Mac
```

**For older macOS versions (pre-Ventura):**
```bash
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -kill -r -domain local -domain user
```

## Checking System Restrictions

### Configuration Profiles

List installed profiles:
```bash
# User-level profiles
profiles list

# System-level profiles (requires admin)
sudo profiles list

# Show all profile details
sudo profiles show -all
```

### MDM Enrollment Status

Check if Mac is enrolled in enterprise MDM:
```bash
profiles show -type enrollment
```

### Keychain Access Issues

If scripts can't access Keychain:
```bash
# List keychain items
security find-generic-password -a "CACI-SecureResources" -s "KeePassXC-DB"
security find-internet-password -s "bitbucket.devopsbase.com"

# Test retrieval (will prompt for access)
security find-generic-password -a "CACI-SecureResources" -s "KeePassXC-DB" -w
```

## Application Bundle Identifiers

Common CACI tools and their bundle IDs:

| Application | Bundle ID | Notes |
|------------|-----------|-------|
| Microsoft Outlook | `com.microsoft.Outlook` | Exchange/M365 email |
| Apple Mail | `com.apple.mail` | macOS default |
| KeePassXC | `org.keepassxc.keepassxc` | Password manager |
| iTerm2 | `com.googlecode.iterm2` | Terminal emulator |

**Find bundle ID for any app:**
```bash
osascript -e 'id of app "Application Name"'

# Or read from Info.plist
defaults read "/Applications/App Name.app/Contents/Info.plist" CFBundleIdentifier
```

## Getting Help

For issues related to:
- **Enterprise policies/MDM:** Contact CACI IT Help Desk
- **Script bugs/improvements:** Open issue in caci-tools repository
- **Tool-specific problems:** Check tool's official documentation (KeePassXC, iTerm2, etc.)
