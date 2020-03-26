import macros
type Holder = object
  val: NimNode

macro bug(n: untyped): untyped =
  let node = Holder(val: n[0])
  node.val[1] = newLit(2)
  result = n

var y = bug: 0 * 2
doAssert(y == 4)
