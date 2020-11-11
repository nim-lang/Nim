discard """
  output: '''3
OK
56
123
56
61'''
"""

import macros

# Bug from the forum
macro addEcho1(s: untyped): untyped =
  s.body.add(newCall("echo", newStrLitNode("OK")))
  result = s

proc f1() {.addEcho1.} =
  let i = 1+2
  echo i

f1()

# bug #537
proc test(): seq[NimNode] {.compiletime.} =
  result = @[]
  result.add parseExpr("echo 56")
  result.add parseExpr("echo 123")
  result.add parseExpr("echo 56")

proc foo(): seq[NimNode] {.compiletime.} =
  result = @[]
  result.add test()
  result.add parseExpr("echo(5+56)")

macro bar() =
  result = newNimNode(nnkStmtList)
  let x = foo()
  for xx in x:
    result.add xx
  echo treeRepr(result)

bar()
