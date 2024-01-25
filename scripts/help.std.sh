#!/usr/bin/env bash
# HELPTEXT: Display this help output

set -Eeou pipefail

show_help_for_extension() {
    EXT="$1"
    for f in scripts/*"$EXT"; do
        # get just the file name
        filename="$(basename "$f")"
        # strip the two part extension
        cmd="${filename%"${EXT}"}"
        # Search the file for the HELPTEXT string, only return the first match
        helptext_raw="$(grep -oP "# HELPTEXT:\K.*" "$f" | head -1 || true)"
        # Trim leading whitespace from HELPTEXT
        helptext="${helptext_raw##*( )}"
        # Finally, print out the help line for this command
        printf '  %-28s %s\n' "$cmd" "$helptext"
    done
}

printf "\nUsage: ./run <command> [args...]\n"

printf "\nStandard commands:\n"
show_help_for_extension ".std.sh"

printf "\nTerraform commands:\n"
show_help_for_extension ".tf.sh"

printf "\nnote: any arguments passed after <command> are passed directly to the script that handles that command.\n\n"
