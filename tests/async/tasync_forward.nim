
import asyncdispatch

# bug #1970

proc foo {.async.}

proc foo {.async.} =
  discard
