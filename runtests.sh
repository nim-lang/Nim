#!/bin/sh
nim c --path:src -r --verbosity:0 --hints:off --linedir:on --debuginfo \
  --stacktrace:on --linetrace:on "$@" ./test/testall.nim \
  | grep -vE 'ProveInit|instantiation from here'
