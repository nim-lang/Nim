import macros

macro test1(): untyped =
  # var x = 0
  # var y = 0
  let x = genSym(nskVar)
  let y = genSym(nskVar)
  #let z = freshIdentNodes(x)
  result = newStmtList(newVarStmt(x, newLit(0)), newVarStmt(y, newLit(0)))

macro test2(): untyped =
  let x = getAst test1()
  result = freshIdentNodes(x)

test1()
test2()
