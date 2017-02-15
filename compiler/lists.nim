#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module is deprecated, don't use it.
# TODO Remove this

import os

static:
  echo "WARNING: imported deprecated module compiler/lists.nim, use seq ore lists from the standard library"

proc appendStr*(list: var seq[string]; data: string) {.deprecated.} =
  # just use system.add
  list.add(data)

proc includeStr(list: var seq[string]; data: string): bool {.deprecated.} =
  if list.contains(data):
    result = true
  else:
    result = false
    list.add data

