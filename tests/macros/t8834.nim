discard """
  output: "12"
"""

# bug #8834: `varargs[typed]` of a template passed on to `varargs[untyped]`
import std/macros

macro strAddFrom(src: var string, args: varargs[untyped]): untyped =
  result = newStmtList()
  var myBlock = newStmtList()
  for ai in args:
    myBlock.add quote do:
      `src`.add $`ai`
  result.add newBlockStmt(myBlock)

template strAdd(args: varargs[typed]): untyped =
  block:
    var ret = ""
    strAddFrom(ret, args)
    ret

echo strAdd(1, 2)
