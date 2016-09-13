discard """
  file: "tasyncsend4754.nim"
  output: "Finished"
"""

import asyncdispatch

proc f(): Future[void] {.async.} =
  let s = newAsyncNativeSocket()
  await s.connect("example.com", 80.Port)
  await s.send("123")
  echo "Finished"

waitFor f()
