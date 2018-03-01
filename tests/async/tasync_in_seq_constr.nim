discard """
  errormsg: "invalid control flow: 'yield' within a constructor"
  line: 16
"""

# bug #5314, bug #6626

import asyncdispatch

proc bar(): Future[int] {.async.} =
    await sleepAsync(500)
    result = 3

proc foo(): Future[seq[int]] {.async.} =
    await sleepAsync(500)
    result = @[1, 2, await bar(), 4] # <--- The bug is here

echo waitFor foo()
