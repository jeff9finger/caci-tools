#!/bin/bash
# iTerm invokes this script as if it is keepassxc-cli

# Log all arguments to a file
echo "$(date): Called with $# arguments" >> /tmp/iterm-keepass-debug.log
echo "Args: $@" >> /tmp/iterm-keepass-debug.log
echo "arg0: $0" >> /tmp/iterm-keepass-debug.log
echo "arg1: $1" >> /tmp/iterm-keepass-debug.log
echo "arg2: $2" >> /tmp/iterm-keepass-debug.log
echo "arg3: $3" >> /tmp/iterm-keepass-debug.log
echo "arg4: $4" >> /tmp/iterm-keepass-debug.log
echo "arg5: $5" >> /tmp/iterm-keepass-debug.log
echo "---" >> /tmp/iterm-keepass-debug.log
sync

# First argument is the command (ls, show, etc.)
keepass_cmd="$1"
shift

# Collect all flag arguments (start with --)
# Some flags take arguments, so need to track them
cmd_args=()
positional_args=()

# Convert remaining args to array for easier indexing
args=("$@")
i=0
while [[ $i -lt ${#args[@]} ]]; do
    arg="${args[$i]}"
    if [[ "$arg" == --* ]] || [[ "$arg" == -* ]]; then
        cmd_args+=("$arg")
        # Check if this flag takes an argument
        # Flags that take args: -k/--key-file, -a/--attributes, -y/--yubikey
        if [[ "$arg" =~ ^(-a|--attributes|-k|--key-file|-y|--yubikey)$ ]]; then
            # Next arg is the flag's value
            i=$((i + 1))
            if [[ $i -lt ${#args[@]} ]]; then
                cmd_args+=("${args[$i]}")
            fi
        fi
    else
        positional_args+=("$arg")
    fi
    i=$((i + 1))
done

# Now inject --key-file after the command
keepass_keyfile="/Users/jeff.haynes_cn/.keepassxc/CACI-SecureResources.keyx"

# For ls command with --flatten --recursive, prepend "iTerm2/" to all output lines
# For show/edit/rm commands, REMOVE iTerm2/ prefix from entry path (inverse transform)
if [[ "$keepass_cmd" == "ls" ]] && [[ " ${cmd_args[@]} " =~ " --flatten " ]] && [[ " ${cmd_args[@]} " =~ " --recursive " ]]; then
    # List command: transform output to add iTerm2/ prefix
    # Read all stdin first (password), then run command with it
    stdin_content=$(cat)
#    echo "$stdin_content" | /Users/jeff.haynes_cn/Applications/KeePassXC.app/Contents/MacOS/keepassxc-cli "${keepass_cmd}" "${cmd_args[@]}" --key-file "${keepass_keyfile}" "${positional_args[@]}" | while IFS= read -r line; do
    echo "$stdin_content" | /opt/homebrew/bin/keepassxc-cli "${keepass_cmd}" "${cmd_args[@]}" --key-file "${keepass_keyfile}" "${positional_args[@]}" | while IFS= read -r line; do
        # Skip empty lines, Recycle Bin, folder-only entries (trailing /), and lines already starting with iTerm2/
        if [[ -n "$line" ]] && [[ ! "$line" =~ ^Recycle\ Bin ]] && [[ ! "$line" =~ /$ ]] && [[ ! "$line" =~ ^iTerm2/ ]]; then
            echo "iTerm2/$line"
        elif [[ "$line" =~ ^iTerm2/ ]] && [[ ! "$line" =~ /$ ]]; then
            # Already has iTerm2 prefix and not a folder, pass through
            echo "$line"
        fi
    done
    exit $?
elif [[ "$keepass_cmd" =~ ^(show|edit|rm)$ ]] && [[ ${#positional_args[@]} -gt 1 ]]; then
    # For read/edit/delete operations, REMOVE iTerm2/ prefix from entry path
    # Entry path is everything after database path (handle spaces in entry names)
    # positional_args: [Password, /path/to/db.kdbx, iTerm2/Entry, Name, With, Spaces]
    # OR: [/path/to/db.kdbx, iTerm2/Entry, Name]

    # Find database path (ends with .kdbx)
    db_idx=-1
    for i in "${!positional_args[@]}"; do
        if [[ "${positional_args[$i]}" == *.kdbx ]]; then
            db_idx=$i
            break
        fi
    done

    if [[ $db_idx -ge 0 ]] && [[ $db_idx -lt $((${#positional_args[@]} - 1)) ]]; then
        # Everything after database is the entry path (may have spaces)
        entry_start=$((db_idx + 1))
        entry_parts=("${positional_args[@]:$entry_start}")
        entry_path="${entry_parts[*]}"  # Join with spaces

        echo "BEFORE transform: $entry_path" >> /tmp/iterm-keepass-debug.log
        # Strip iTerm2/ prefix if present
        entry_path="${entry_path#iTerm2/}"
        echo "AFTER transform: $entry_path" >> /tmp/iterm-keepass-debug.log

        # Rebuild positional_args: everything up to db, then transformed entry as single arg
        new_positional_args=("${positional_args[@]:0:$entry_start}" "$entry_path")

        echo "Final command: ${keepass_cmd} ${cmd_args[@]} --key-file ... ${new_positional_args[@]}" >> /tmp/iterm-keepass-debug.log
        echo "Entry path arg count: ${#new_positional_args[@]}" >> /tmp/iterm-keepass-debug.log
        for idx in "${!new_positional_args[@]}"; do
            echo "  positional[$idx]: '${new_positional_args[$idx]}'" >> /tmp/iterm-keepass-debug.log
        done
        sync

        # Capture stderr for debugging
        /Users/jeff.haynes_cn/Applications/KeePassXC.app/Contents/MacOS/keepassxc-cli "${keepass_cmd}" "${cmd_args[@]}" --key-file "${keepass_keyfile}" "${new_positional_args[@]}" 2>> /tmp/iterm-keepass-error.log
        exit_code=$?
        echo "Exit code: $exit_code" >> /tmp/iterm-keepass-debug.log
        exit $exit_code
    else
        # Fallback: use original logic
        exec /Users/jeff.haynes_cn/Applications/KeePassXC.app/Contents/MacOS/keepassxc-cli "${keepass_cmd}" "${cmd_args[@]}" --key-file "${keepass_keyfile}" "${positional_args[@]}"
    fi
elif [[ "$keepass_cmd" =~ ^(add|mkdir)$ ]] && [[ ${#positional_args[@]} -gt 1 ]]; then
    # For add/mkdir operations, also REMOVE iTerm2/ prefix
    # Entries created at root level, not in iTerm2 folder

    # Find database path (ends with .kdbx)
    db_idx=-1
    for i in "${!positional_args[@]}"; do
        if [[ "${positional_args[$i]}" == *.kdbx ]]; then
            db_idx=$i
            break
        fi
    done

    if [[ $db_idx -ge 0 ]] && [[ $db_idx -lt $((${#positional_args[@]} - 1)) ]]; then
        # Everything after database is the entry path (may have spaces)
        entry_start=$((db_idx + 1))
        entry_parts=("${positional_args[@]:$entry_start}")
        entry_path="${entry_parts[*]}"  # Join with spaces

        # Strip iTerm2/ prefix if present
        entry_path="${entry_path#iTerm2/}"

        # Rebuild positional_args: everything up to db, then transformed entry as single arg
        new_positional_args=("${positional_args[@]:0:$entry_start}" "$entry_path")

        exec /Users/jeff.haynes_cn/Applications/KeePassXC.app/Contents/MacOS/keepassxc-cli "${keepass_cmd}" "${cmd_args[@]}" --key-file "${keepass_keyfile}" "${new_positional_args[@]}"
    else
        # Fallback: use original logic
        exec /Users/jeff.haynes_cn/Applications/KeePassXC.app/Contents/MacOS/keepassxc-cli "${keepass_cmd}" "${cmd_args[@]}" --key-file "${keepass_keyfile}" "${positional_args[@]}"
    fi
else
    # All other commands, pass through unchanged
    exec /Users/jeff.haynes_cn/Applications/KeePassXC.app/Contents/MacOS/keepassxc-cli "${keepass_cmd}" "${cmd_args[@]}" --key-file "${keepass_keyfile}" "${positional_args[@]}"
fi
