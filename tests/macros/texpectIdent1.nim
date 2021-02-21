discard """
errormsg: "Expected identifier to be `foo` here"
line: 18
"""

import macros

macro testUntyped(arg: untyped): void =
  arg.expectKind nnkStmtList
  arg.expectLen 2
  arg[0].expectKind nnkCall
  arg[0][0].expectIdent "foo"  # must pass
  arg[1].expectKind nnkCall
  arg[1][0].expectIdent "foo"  # must fail

testUntyped:
  foo(123)
  bar(321)
