# issue #5617, feature request
# Ability to set a NimNode's lineinfo
import macros

type
  Test = object

macro mixer(n: typed): untyped =
  let x = newIdentNode("echo")
  x.copyLineInfo(n)
  result = newLit(x.lineInfo == n.lineInfo)

var z = mixer(Test)
doAssert z
