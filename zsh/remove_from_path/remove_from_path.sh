# Function to remove a directory from PATH
#
# Usage:
#   remove_from_path "/path/to/remove"
#
# Arguments:
#   $1 - The directory path to remove from PATH
#
# Description:
#   Removes all occurrences of the specified directory from PATH.
#
# Edge cases handled:
#   - Handles directories with spaces in the name
#   - Maintains : at the start/end of PATH if originally present
#   - Handles cases where the directory appears multiple times in PATH
#   - Avoids creating empty entries or consecutive colons
remove_from_path() {
    if [ -z "$1" ]; then
        echo "Usage: remove_from_path <directory>" >&2
        return 1
    fi

    # Store the original first and last characters of PATH
    first_char="${PATH%"${PATH#?}"}"
    last_char="${PATH#"${PATH%?}"}"

    # Remove all occurrences of the directory, handle spaces in path names
    new_path=$(echo "$PATH" | sed -e "s#^$1:##" -e "s#:$1:##g" -e "s#:$1\$##")

    # If PATH was changed, remove any resulting empty entries and duplicate colons
    if [ "$new_path" != "$PATH" ]; then
        new_path=$(echo "$new_path" | sed -e 's#^:##' -e 's#:$##' -e 's#::+#:#g')

        # Restore leading/trailing colon if they were present originally
        [ "$first_char" = ":" ] && new_path=":$new_path"
        [ "$last_char" = ":" ] && new_path="$new_path:"

        PATH="$new_path"
    fi
}
