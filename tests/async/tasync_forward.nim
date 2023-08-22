
import asyncdispatch

# bug #1970

proc foo {.async.}

proc foo {.async.} =
  discard

# With additional pragmas:
proc bar {.async, cdecl.}

proc bar {.async.} =
  discard

proc verifyCdeclPresent(p: proc : Future[void] {.cdecl.}) = discard
verifyCdeclPresent(bar)
