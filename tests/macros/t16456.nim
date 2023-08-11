discard """
  errormsg: "type mismatch: got <NimNode>"
"""

import macros

macro bugcheck(body: static NimNode): untyped =
  body

bugcheck(newStmtList())
