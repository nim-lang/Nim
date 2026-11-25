discard """
  output: "tick 1\ntick 2\ntick 3"
"""

# The dispatcher of std/asyncdispatch is a threadvar of that module.

import std/asyncdispatch

proc tick(n: int) {.async.} =
  for i in 1 .. n:
    await sleepAsync(1)
    echo "tick ", i

waitFor tick(3)
