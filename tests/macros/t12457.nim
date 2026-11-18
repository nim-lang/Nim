# bug #12457: a NimNode stored in a tuple is not copied
import macros

macro bug(n: untyped): untyped =
  let (node, ) = (n[0], )
  node[1] = newLit(2)
  result = n

var y = bug: 0 * 2
doAssert y == 4
