#!/bin/sh

# Set this to the full path of your nimrod compiler
# since Xcode doesn't inherit your user environment.
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

DEST_NIMBASE=build/nimcache/nimbase.h

# Ok, are we out now?
if [ -d src ]
then
	$PATH_TO_NIMROD objc --noMain  --app:lib \
		--nimcache:./build/nimcache --compileOnly \
		--header --cpu:i386 ../nimrod_backend/backend.nim
	if [ "${PATH_TO_NIMBASE}" -nt "${DEST_NIMBASE}" ]
	then
		echo "Updating nimbase.h"
		cp "${PATH_TO_NIMBASE}" "${DEST_NIMBASE}"
	fi
else
	echo "Uh oh, src directory not found?"
	exit 1
fi
