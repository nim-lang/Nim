discard """
  cmd: '''nim c --gc:arc $file'''
  output: '''
other
'''
"""

import std/macros

macro bigCaseStmt(arg: untyped): untyped =
  result = nnkCaseStmt.newTree(arg)

  # try to change 2000 to a bigger value if it doesn't crash
  for x in 0 ..< 2000:
    result.add nnkOfBranch.newTree(newStrLitNode($x), newStrLitNode($x))

  result.add nnkElse.newTree(newStrLitNode("other"))

macro bigIfElseExpr(): untyped =
  result = nnkIfExpr.newTree()

  for x in 0 ..< 1000:
    result.add nnkElifExpr.newTree(newLit(false), newStrLitNode($x))

  result.add nnkElseExpr.newTree(newStrLitNode("other"))

proc test(arg: string): string =
  echo bigIfElseExpr()

  result = bigCaseStmt(arg)

discard test("test")
