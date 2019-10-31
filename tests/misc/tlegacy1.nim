discard """
cmd: "nim c --legacy:optOldDoNode $file"
"""
# Test the legacy mode ``optOldDoNode``.

import macros

# test that the `do` node is removed for macros if it doesn't have parameters.
macro foo(arg0, arg: untyped) =
  doAssert arg.kind == nnkStmtList

foo(123) do:
  echo 123

# test that a stmtList implicitly converts into a lambde
# expression. This only holds true not nnkStmtList, not for
# nnkStmtListExpr or just a single statement.
type
  VoidProc = proc(): void

proc bar(arg: VoidProc) =
  echo 123

bar:
  echo 321
