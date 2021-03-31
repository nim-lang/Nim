discard """
  output: 42
"""

import asyncdispatch

template foo() =
  proc temp(): Future[int] {.async.} = return 42
  proc tempVoid(): Future[void] {.async.} = echo await temp()

foo()
waitFor tempVoid()
