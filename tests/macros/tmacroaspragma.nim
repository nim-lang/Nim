import macros

macro foo(x: untyped): untyped =
  echo treerepr(callsite())
  result = newNimNode(nnkStmtList)

proc zoo() {.foo.} = echo "hi"
