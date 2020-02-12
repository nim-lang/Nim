discard """
errormsg: "Expected identifier to be `foo` here"
line: 24
"""

import macros

macro testTyped(arg: typed): void =
  arg.expectKind nnkStmtList
  arg.expectLen 2
  arg[0].expectKind nnkCall
  arg[0][0].expectIdent "foo"  # must pass
  arg[1].expectKind nnkCall
  arg[1][0].expectIdent "foo"  # must fail

proc foo(arg: int) =
  discard

proc bar(arg: int) =
  discard

testTyped:
  foo(123)
  bar(321)
