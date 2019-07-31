import macros

macro foo(x: untyped): untyped =
  echo treerepr(x)
  result = newNimNode(nnkStmtList)

proc zoo() {.foo.} = echo "hi"
