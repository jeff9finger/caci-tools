# KeePass Helper Scripts

## iterm-keepass-helper.sh

Wrapper script for `keepassxc-cli` that:

1. Injects `--key-file` parameter automatically
2. Transforms entry paths bidirectionally:
   - `ls` output: adds `iTerm2/` prefix to root entries
   - `show/edit/add/rm` input: removes `iTerm2/` prefix before accessing DB
3. Handles entry names with spaces correctly
4. Logs all invocations to `/tmp/iterm-keepass-debug.log`

### Usage

In iTerm2 Password Manager settings:
- Password Manager: KeePassXC
- Path to executable: `/Users/USERNAME/bin/iterm-keepass-helper.sh`

### Configuration

Edit script to change:
- `keepass_keyfile` - path to your .keyx file
- Path to KeePassXC.app

### How It Works

iTerm2 adapter expects entries in `iTerm2/` group, but this script makes root-level entries appear as if they're in that group. No need to move/copy entries in your database.

### Debugging

Check logs:
- `/tmp/iterm-keepass-debug.log` - all invocations and transformations
- `/tmp/iterm-keepass-error.log` - keepassxc-cli stderr output
