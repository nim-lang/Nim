discard """
  output: '''0 1
1 2
2 3
0 1
1 2
2 3
0 1
1 2
2 3
3 5'''
"""

import macros

macro mymacro(): untyped =
  result = newLit([1, 2, 3])

for a, b in mymacro():
  echo a, " ", b

macro enumerate(x: ForLoopStmt): untyped =
  expectKind x, nnkForStmt
  # we strip off the first for loop variable and use
  # it as an integer counter:
  result = newStmtList()
  result.add newVarStmt(x[0], newLit(0))
  var body = x[^1]
  if body.kind != nnkStmtList:
    body = newTree(nnkStmtList, body)
  body.add newCall(bindSym"inc", x[0])
  var newFor = newTree(nnkForStmt)
  for i in 1..x.len-3:
    newFor.add x[i]
  # transform enumerate(X) to 'X'
  newFor.add x[^2][1]
  newFor.add body
  result.add newFor

for a, b in enumerate(items([1, 2, 3])):
  echo a, " ", b

for a2, b2 in enumerate([1, 2, 3, 5]):
  echo a2, " ", b2
