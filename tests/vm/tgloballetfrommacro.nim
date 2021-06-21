discard """
errormsg: "cannot evaluate at compile time: BUILTIN_NAMES"
line: 11
"""

import sets

let BUILTIN_NAMES = toHashSet(["int8", "int16", "int32", "int64"])

macro test*(): bool =
  echo "int64" notin BUILTIN_NAMES

echo test()
