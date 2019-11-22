discard """
  output: "after"
"""

import macros

macro test_macro*(s: string, n: untyped): untyped =
  result = newNimNode(nnkStmtList)
  var ass : NimNode = newNimNode(nnkAsgn)
  add(ass, newIdentNode("str"))
  add(ass, newStrLitNode("after"))
  add(result, ass)
when true:
  var str: string = "before"
  test_macro(str):
    var i : integer = 123
  echo str
