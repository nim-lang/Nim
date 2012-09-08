#!/bin/sh

# Force errors to fail script.
set -e

# If we are running from inside the scripts subdir, get out.
if [ ! -d src ]
then
	cd ..
fi

# Ok, are we out now?
if [ -d src ]
then
	javah -classpath bin/classes \
		-o jni/backend-jni.h \
		com.github.nimrod.crosscalculator.CrossCalculator
else
	echo "Uh oh, bin/classes directory not found?"
	echo "Try compiling your java code, or opening in eclipse."
	exit 1
fi
