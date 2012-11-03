#!/bin/sh

rm -f nimtodo
nimrod c --path:../nimrod_backend nimtodo.nim && \
	echo "Build successful."
