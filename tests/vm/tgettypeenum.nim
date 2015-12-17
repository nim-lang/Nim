discard """
  output: '''PGO'''
"""

import macros

type
  PGO* = enum
    PORTRAIT, LANDSCAPE
  
macro mixer(arg: typed): stmt =
  let a = getType(arg)[0]
  result = parseExpr("echo \"" & $a & "\"")
  
mixer(PORTRAIT)

