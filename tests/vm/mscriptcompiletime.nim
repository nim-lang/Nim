# bug.nim
var bar* {.compileTime.} = 1

proc dummy = discard

static:
  inc bar