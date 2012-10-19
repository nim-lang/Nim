import macros

macro foo(x: stmt): stmt =
  echo treerepr(callsite())
  result = newNimNode(nnkStmtList)

proc zoo() {.foo.} = echo "hi"

