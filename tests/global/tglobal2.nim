# b.nim
import a_module
doAssert foo() == 0

proc hello(x: type) =
  var s {.global.} = default(x)
  doAssert s == 0

hello(int)
