discard """
errormsg: "invalid order of case branches"
"""

import macros

macro genCase(val: string): untyped =
  result = nnkCaseStmt.newTree(val,
    nnkElse.newTree(quote do: echo "else"),
    nnkOfBranch.newTree(newLit("miauz"), quote do: echo "first branch"))

genCase("miauz")
