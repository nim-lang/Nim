discard """
  errormsg: "Cannot make async proc discardable. Futures have to be checked with `asyncCheck` instead of discarded"
"""

import async

proc foo {.async, discardable.} = discard

foo()
