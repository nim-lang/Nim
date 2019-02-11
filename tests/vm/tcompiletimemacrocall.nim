import macros
let x = 10
let a {.compileTime.} : NimNode = bindSym"x"
static:
  doAssert $a == "x"
