#!/bin/sh
# Prints its arguments between markers and its working directory, one per
# line; `--exit N` exits with N instead.
if [ "$1" = "--exit" ]; then exit "$2"; fi
printf '<'
for a in "$@"; do printf '%s|' "$a"; done
printf '>\n'
printf 'cwd=%s\n' "$(pwd -P)"
