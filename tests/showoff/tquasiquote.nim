discard """
  outputsub: '''tquasiquote.nim(14, 8): Check failed: 1 > 2'''
"""

import macros

macro check(ex: untyped): untyped =
  var info = ex.lineInfo
  var expString = ex.toStrLit
  result = quote do:
    if not `ex`:
      echo `info`, ": Check failed: ", `expString`

check 1 > 2
