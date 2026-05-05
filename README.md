# CACI DevOps Tools

Collection of automation scripts for CACI DevOpsBase infrastructure.

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

---

## refresh-token.sh

Automates daily token refresh for Artifactory and Bitbucket access. Retrieves tokens from both systems and stores the Bitbucket token in macOS Keychain for Git authentication.

### What It Does

1. **Retrieves DevOpsBase password** from KeePassXC (secured with keyfile)
2. **Gets Artifactory token** (reference_token for future use - storage TBD)
3. **Gets Bitbucket HTTP access token** (valid for 24 hours)
4. **Stores Bitbucket token** in macOS Keychain for automatic Git authentication

### Prerequisites

- **KeePassXC** with your DevOpsBase credentials
- **SurePass 2FA** authenticator app on your phone
- **jq** installed: `brew install jq`
- **keepassxc-cli** available in PATH (installed with KeePassXC)
- macOS Keychain Access (built-in)

### Assumptions

The script expects the following setup:

1. **KeePass Database Location:**
   - Database file: `~/.keepassxc/CACI-SecureResources.kdbx`
   - Key file: `~/.keepassxc/CACI-SecureResources.keyx`
   - *(Update paths in script if your files are located elsewhere)*

2. **KeePass Entry Structure:**
   - Entry name: `DevOpsBase`
   - This entry must contain your DevOpsBase password in the "Password" field
   - *(Change `KEEPASS_ENTRY` variable in script if your entry has a different name)*

3. **macOS Keychain Entry:**
   - Account: `CACI-SecureResources`
   - Service: `KeePassXC-DB`
   - Contains: Your KeePass database master password
   - This allows the script to unlock KeePassXC without prompting

4. **Network Access:**
   - Must be able to reach `artifactory.devopsbase.com` (HTTPS)
   - Must be able to reach `bitbucket.devopsbase.com` (HTTPS)

5. **Git Configuration:**
   - Git credential helper must be set to `osxkeychain`
   - Check with: `git config --get credential.helper`
   - Set if needed: `git config --global credential.helper osxkeychain`

### Installation

1. **Store KeePassXC database password in macOS Keychain:**
   ```bash
   security add-generic-password -a 'CACI-SecureResources' -s 'KeePassXC-DB' -w
   # Enter your KeePass database master password when prompted
   ```

2. **Update configuration in the script:**
   ```bash
   # Edit these variables at the top of refresh-token.sh:
   USERNAME="your-username"
   KEEPASS_DB="${HOME}/.keepassxc/your-database.kdbx"
   KEEPASS_KEYFILE="${HOME}/.keepassxc/your-database.keyx"
   KEEPASS_ENTRY="DevOpsBase"  # Entry name in KeePassXC containing your password
   ```

3. **Make executable:**
   ```bash
   chmod +x ~/github/caci-tools/refresh-token.sh
   ```

### Usage

The script has three modes of operation:

```bash
# Get both Artifactory and Bitbucket tokens (default)
~/github/caci-tools/refresh-token.sh
~/github/caci-tools/refresh-token.sh both

# Get only Artifactory token (saves to .artifactory_credentials)
~/github/caci-tools/refresh-token.sh artifactory

# Get only Bitbucket token (saves to keychain for Git)
~/github/caci-tools/refresh-token.sh bitbucket
```

**Important:** When running in `both` or `artifactory`+`bitbucket` modes, the script will prompt for **TWO SurePass codes** during execution:

1. **First SurePass code** - for Artifactory token request
2. **Second SurePass code** - for Bitbucket token request (wait ~30 seconds for next code)

**Why two codes?** SurePass codes expire quickly (typically 30 seconds). Because the script makes two separate API calls to different systems (Artifactory and Bitbucket), the first code will have expired by the time the second request is made. You must wait for a fresh code after the first request completes.

### How It Works

1. Retrieves your KeePass database password from macOS Keychain (stored during installation)
2. Uses that to unlock KeePassXC and get your DevOpsBase password
3. **Artifactory mode:**
   - Combines password with SurePass code → requests Artifactory token
   - Extracts `reference_token` from response
   - Saves to `.artifactory_credentials` in current directory (format: `ARTIFACTORY_USERNAME=...` and `ARTIFACTORY_KEY=...`)
4. **Bitbucket mode:**
   - Combines password with SurePass code → requests Bitbucket access token (24-hour expiry)
   - Stores token in macOS Keychain with protocol "htps" (HTTPS)
   - Git automatically uses this token when accessing `https://bitbucket.devopsbase.com`

### Testing

After running the script, test Git authentication:

```bash
git clone https://bitbucket.devopsbase.com/scm/PROJECT/REPO.git
```

**First-time keychain access:** When Git first accesses the stored token for a repository, macOS Keychain will prompt for your login password. Enter your macOS login password and click **"Always Allow"** to prevent future prompts for this credential. After that, Git will use the token automatically without any prompts.

To verify the token is stored:

```bash
security find-internet-password -s "bitbucket.devopsbase.com" -a "your-username"
```

### Troubleshooting

**"Failed to retrieve KeePass database password from Keychain":**
- Run the installation step 1 again to store the password

**"Authentication failed" for Artifactory or Bitbucket:**
- Verify your DevOpsBase password is correct in KeePassXC
- Ensure you're using a fresh SurePass code (not expired)
- Wait for a new code if prompted too quickly after the previous one

**Git still prompts for password:**
- Verify token is stored: `security find-internet-password -s "bitbucket.devopsbase.com"`
- Check Git credential helper: `git config --get credential.helper` (should show "osxkeychain")
- Token may have expired (24 hour lifetime) - run script again

### Notes

- Bitbucket tokens expire after 24 hours - run daily
- Artifactory reference_token is extracted but not yet stored (TODO: determine storage location)
- The script uses `set -e` - any command failure will abort execution
