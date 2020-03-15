#!/usr/bin/env bash

# Exit if anything fails
set -e

which nim > /dev/null || (echo "nim not in PATH"; exit 1)
which gdb > /dev/null || (echo "gdb not in PATH"; exit 1)
which readlink > /dev/null || \
    which greadline > /dev/null || \
    ([[ "$OSTYPE" != "darwin"* ]] && \
        (echo "readlink not in PATH. Please install coreutils from homebrew."; exit 1)) || \
    (echo "readlink not in PATH."; exit 1)

nreadlink () {
    (which greadlink > /dev/null && greadlink "$@") || \
    (which readlink > /dev/null && readlink "$@") || \
    echo "Readlink could not be found"
}

# Find out where the pretty printer Python module is
NIM_SYSROOT=$(dirname $(dirname $(nreadlink -e $(which nim))))
GDB_PYTHON_MODULE_PATH="$NIM_SYSROOT/tools/nim-gdb.py"

# Run GDB with the additional arguments that load the pretty printers
# Set the environment variable `NIM_GDB` to overwrite the call to a
# different/specific command (defaults to `gdb`).
NIM_GDB="${NIM_GDB:-gdb}"
# exec replaces the new process of bash with gdb. It is always good to
# have fewer processes.
exec "${NIM_GDB}" -eval-command="source $GDB_PYTHON_MODULE_PATH" "$@"
