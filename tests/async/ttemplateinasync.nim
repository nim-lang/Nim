discard """
  output: 42
"""

import asyncdispatch

proc foo(): Future[int] {.async.} =
  template ret() = return 42
  ret()

echo (waitFor foo())
