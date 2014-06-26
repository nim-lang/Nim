#!/bin/sh

# Set this to the local or full path of your nimrod compiler
PATH_TO_NIMROD=~/project/nimrod/bin/nimrod
# Set this to the location of the nimbase.h file so
# the script can update it if it changes.
PATH_TO_NIMBASE=~/project/nimrod/lib/nimbase.h

# Force errors to fail script.
set -e

# If we are running from inside the scripts subdir, get out.
if [ ! -d src ]
then
	cd ..
fi

DEST_NIMBASE=jni/nimcache/nimbase.h

# Ok, are we out now?
if [ -d src ]
then
	$PATH_TO_NIMROD c --noMain  --app:lib \
		--nimcache:jni/nimcache --cpu:arm --os:linux \
		--compileOnly --header ../nimrod_backend/*.nim
	if [ "${PATH_TO_NIMBASE}" -nt "${DEST_NIMBASE}" ]
	then
		echo "Updating nimbase.h"
		cp "${PATH_TO_NIMBASE}" "${DEST_NIMBASE}"
	fi
else
	echo "Uh oh, src directory not found?"
	exit 1
fi
