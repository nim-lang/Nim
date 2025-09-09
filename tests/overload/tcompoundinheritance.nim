# issue #24773

import std/assertions

type
  A {.inheritable.} = object
  B = object of A
  C = object of B

proc add1(v: B) =
  doAssert true

proc add1(v: A) =
  doAssert false

proc add2(v: B, v2: A) =
  doAssert true

proc add2(v: A, v2: A) =
  doAssert false

var x: C
var y: B

add1(x)
add2(x, y)
