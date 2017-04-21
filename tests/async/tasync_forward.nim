
import asyncdispatch

# bug #1970

proc foo {.async.}

proc foo {.async.} =
  discard

# With additional pragmas:
proc bar {.async, inline.}

proc bar {.async.} =
  discard
