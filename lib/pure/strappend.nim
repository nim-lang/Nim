import std/macros

macro strAddFrom*(src: var string, args: varargs[typed]): untyped =
  ## like ``echo`` but returns a string
  runnableExamples:
    var s = ""
    s.strAddFrom()
    doAssert s == ""
    s.strAddFrom(1+2, "foo")
    doAssert s == "3foo"
  result = newStmtList()
  var myBlock = newStmtList()
  for ai in args:
    myBlock.add quote do:
      `src`.add $`ai`
  result.add newBlockStmt(myBlock)

macro strAdd*(args: varargs[typed]): untyped =
  ## like ``echo`` but returns a string
  runnableExamples:
    doAssert strAdd() == ""
    doAssert strAdd(1+2, "foo") == "3foo"

  var myBlock = newStmtList()
  var ret = genSym(nskVar, "ret")
  myBlock.add newVarStmt(ret, newStrLitNode(""))

  let call = newCall(bindSym"strAddFrom")
  call.add ret
  for i in 0 ..< args.len:
    call.add args[i]
  myBlock.add call
  myBlock.add ret

  result = newStmtList()
  result.add newBlockStmt(myBlock)

when isMainModule:
  ## PENDING https://github.com/nim-lang/Nim/issues/7280
  discard strAdd()
