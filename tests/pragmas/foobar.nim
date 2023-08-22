import macros
macro async*(body: untyped): untyped =
  return newStmtList()
