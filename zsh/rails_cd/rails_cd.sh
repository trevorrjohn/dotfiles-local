#!/bin/sh

# Function to override the cd command
#
# Usage:
#   cd [directory]
#
# Arguments:
#   [directory] - The directory to change to. If omitted, changes to the home directory.
#
# Description:
#   This function overrides the built-in cd command. It changes the current
#   directory and manages the PATH based on the presence of a ./bin/rails file.
#
# Edge cases handled:
#   - Fails gracefully if the target directory doesn't exist
#   - Checks if the old directory still exists before modifying PATH
#   - Verifies both existence and readability of bin/rails files
#   - Works with relative and absolute paths
#   - Handles 'cd' with no arguments (change to home directory)
#   - Handles spaces in directory names
cd() {
    old_dir="$PWD"

    # Check if another cd function is defined
    if type cd_func > /dev/null 2>&1; then
        cd_func "$@"
    else
        # Attempt to change directory using the built-in cd
        if ! command cd "$@" 2>/dev/null; then
            echo "cd: no such file or directory: $*" >&2
            return 1
        fi
    fi

    # The rest of the function remains the same
    if [ "$PWD" != "$old_dir" ]; then
        # Check if old directory still exists and had bin/rails
        if [ -d "$old_dir" ] && [ -f "$old_dir/bin/rails" ]; then
            remove_from_path "$old_dir/bin"
        fi

        # Check if new directory has bin/rails
        if [ -f "./bin/rails" ] && [ -r "./bin/rails" ]; then
            add_to_path "$PWD/bin"
        fi
    fi
}
