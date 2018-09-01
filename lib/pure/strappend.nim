import std/macros

macro strAddFrom*(src: var string, args: varargs[typed]): untyped =
  ## appends stringified ``args`` to ``src``
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

# TODO: consider moving to `macros.nim`
macro varArgsLen*(args: varargs[untyped]): untyped = newIntLitNode(args.len)

template strAdd*(args: varargs[untyped]): untyped =
  ## like ``echo`` but returns a string
  # should use `varargs[typed]` pending https://github.com/nim-lang/Nim/issues/8834
  runnableExamples:
    doAssert strAdd() == ""
    doAssert strAdd(1+2, "foo") == "3foo"
  block:
    var ret=""
    when varArgsLen(args)>0: # PENDING https://github.com/nim-lang/Nim/issues/8833
      strAddFrom(ret, args)
    ret

when isMainModule:
  ## PENDING https://github.com/nim-lang/Nim/issues/7280
  discard strAdd()
