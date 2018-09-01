import std/macros

macro strAppend*(args: varargs[typed]): untyped =
  ## like ``echo`` but returns a string
  runnableExamples:
    doAssert strAppend() == ""
    doAssert strAppend(1+2, "foo") == "3foo"
  result = newStmtList()
  var myBlock = newStmtList()
  var ret = genSym(nskVar, "ret")
  myBlock.add newVarStmt(ret, newStrLitNode(""))
  for i in 0..<args.len:
    let ai = args[i]
    myBlock.add quote do:
      `ret`.add $`ai`
  myBlock.add quote do:
    `ret`
  result.add newBlockStmt(myBlock)
