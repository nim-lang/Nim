#!/bin/sh

if [ ! -d src ]
then
	cd ..
fi

if [ -d src ]
then
	~/bin/objctags -R \
		jni \
		src
fi
