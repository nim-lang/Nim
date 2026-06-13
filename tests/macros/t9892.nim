discard """
  output: '''1'''
"""
# Issue #9892: Incorrect "Error: not unused" from else branch in macro
# https://github.com/nim-lang/Nim/issues/9892

import macros

macro foo(x: typed): untyped =
  result = newNimNode(nnkStmtListExpr)
  if x.kind == nnkStmtListExpr:
    result.add x
  else:
    result = x

echo foo(1)
