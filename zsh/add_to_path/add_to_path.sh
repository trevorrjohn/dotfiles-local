#!/bin/sh

# Function to add a directory to PATH
#
# Usage:
#   add_to_path "/path/to/add"
#
# Arguments:
#   $1 - The directory path to add to PATH
#
# Description:
#   Adds the specified directory to the beginning of PATH if it's not already present.
#
# Edge cases handled:
#   - Checks if the directory exists and is readable
#   - Avoids adding duplicate entries
#   - Handles directories with spaces in the name
#   - Maintains : at the start/end of PATH if originally present
add_to_path() {
    if [ -z "$1" ]; then
        echo "Usage: add_to_path <directory>" >&2
        return 1
    fi

    if [ ! -d "$1" ]; then
        echo "Error: '$1' is not a directory" >&2
        return 1
    fi

    if [ ! -r "$1" ]; then
        echo "Error: '$1' is not readable" >&2
        return 1
    fi

    case ":$PATH:" in
        *":$1:"*) :;; # Already in PATH
        *)
            if [ "${PATH#:}" != "$PATH" ]; then
                PATH=":$1$PATH" # Maintain leading :
            elif [ "${PATH%:}" != "$PATH" ]; then
                PATH="$1:$PATH:" # Maintain trailing :
            else
                PATH="$1:$PATH"
            fi
            ;;
    esac
}
