# KeePass Helper Scripts

## iterm-keepass-helper.sh

Wrapper script for `keepassxc-cli` that:

1. Injects `--key-file` parameter automatically
2. Transforms entry paths bidirectionally:
   - `ls` output: adds `iTerm2/` prefix to root entries
   - `show/edit/add/rm` input: removes `iTerm2/` prefix before accessing DB
3. Handles entry names with spaces correctly
4. Logs all invocations to `/tmp/iterm-keepass-debug.log`

### Installation

1. **Copy the script to a permanent location:**
   ```bash
   mkdir -p ~/bin
   cp iterm-keepass-helper.sh ~/bin/
   chmod +x ~/bin/iterm-keepass-helper.sh
   ```

2. **Edit the script to set your paths:**
   ```bash
   # Update these variables in the script:
   keepass_keyfile="/Users/USERNAME/.keepassxc/your-database.keyx"
   # And verify the keepassxc-cli path (line 57) matches your installation:
   # - Homebrew: /opt/homebrew/bin/keepassxc-cli
   # - App bundle: /Users/USERNAME/Applications/KeePassXC.app/Contents/MacOS/keepassxc-cli
   ```

3. **Configure iTerm2 using plutil:**
   ```bash
   # Quit iTerm2 first
   osascript -e 'quit app "iTerm"'
   
   # Set KeePassXC as the password manager
   plutil -replace NoSyncPasswordManagerDataSourceName -string "KeePassXC" ~/Library/Preferences/com.googlecode.iterm2.plist
   
   # Set the path to the wrapper script (use absolute path, not ~)
   plutil -replace NoSyncPasswordManagerExecutablePath -string "/Users/$(whoami)/bin/iterm-keepass-helper.sh" ~/Library/Preferences/com.googlecode.iterm2.plist
   ```

   **Note:** If the `NoSyncPasswordManagerExecutablePath` key doesn't exist yet, use `-insert` instead:
   ```bash
   plutil -insert NoSyncPasswordManagerExecutablePath -string "/Users/$(whoami)/bin/iterm-keepass-helper.sh" ~/Library/Preferences/com.googlecode.iterm2.plist
   ```

4. **Restart iTerm2** for settings to take effect

5. **Test the integration:**
   - Open iTerm2 → Window → Password Manager
   - You should see your KeePass entries prefixed with `iTerm2/`

### Alternative: GUI Configuration

If the plutil approach doesn't work, try setting it in iTerm2's UI:
- Open iTerm2 → Settings → Advanced
- Search for "password manager"
- Find "Path to KeePassXC CLI executable" 
- Set to: `/Users/USERNAME/bin/iterm-keepass-helper.sh` (use full path)

### Configuration

Edit script to change:
- `keepass_keyfile` - path to your .keyx file (line 48)
- Path to `keepassxc-cli` executable (line 57 for ls command, lines 103+ for other commands)

### How It Works

iTerm2 adapter expects entries in `iTerm2/` group, but this script makes root-level entries appear as if they're in that group. No need to move/copy entries in your database.

### Debugging

Check logs:
- `/tmp/iterm-keepass-debug.log` - all invocations and transformations
- `/tmp/iterm-keepass-error.log` - keepassxc-cli stderr output

### Troubleshooting

**Script not being called:**
- Verify the path is absolute (not `~/bin/...` but `/Users/USERNAME/bin/...`)
- Check script permissions: `ls -l ~/bin/iterm-keepass-helper.sh`
- Check iTerm2 preference: `plutil -p ~/Library/Preferences/com.googlecode.iterm2.plist | grep -i password`
- Look for errors in Console.app filtering for "iTerm2"

**No entries showing:**
- Check debug log: `tail -f /tmp/iterm-keepass-debug.log`
- Verify keyfile path is correct
- Test script manually: `~/bin/iterm-keepass-helper.sh ls --recursive --flatten` (provide password when prompted)
