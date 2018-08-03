# issue #5617, feature request
# Ability to set a NimNode's lineinfo
import macros

type
  Test = object

macro mixer(n: typed): untyped =
  let x = newIdentNode("echo")
  let y = newStrLitNode("Hello World")
  x.lineInfo = n
  y.lineInfo(n)
  result = newLit(x.lineInfo == y.lineInfo)

var z = mixer(Test)
doAssert z
