discard """
  output: "after"
"""

import
  macros, strutils

macro test_macro*(n: stmt): stmt {.immediate.} =
  result = newNimNode(nnkStmtList)
  var ass : NimNode = newNimNode(nnkAsgn)
  add(ass, newIdentNode("str"))
  add(ass, newStrLitNode("after"))
  add(result, ass)
when isMainModule:
  var str: string = "before"
  test_macro(str):
    var i : integer = 123
  echo str

