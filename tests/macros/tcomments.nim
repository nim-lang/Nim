discard """
  output: "line 1\nline 2"
"""

import
  macros, strutils

macro test_macro*(n: stmt): stmt {.immediate.} =
  result = newNimNode(nnkStmtList)
  for c in n:
    expectKind c, nnkCommentStmt
    let s = c.strVal
    result = quote do:
      echo `s`
when isMainModule:
  test_macro:
    ## line 1
    ## line 2

