import macros

macro lambdaEval*(lambda: untyped, arg:typed):untyped=
  if $lambda[0] != "=>":
    error("Expected `=>` got " & $lambda[0])
  var ret = newStmtList()
  ret.add newLetStmt(lambda[1], arg)
  ret.add lambda[2]
  result = newBlockStmt(ret)
