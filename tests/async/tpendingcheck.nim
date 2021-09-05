discard """
  output: ""
"""

import asyncdispatch

proc test() {.async.} =
  await sleepAsync(50)
type T = typeof(test)
