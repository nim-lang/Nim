type ObjectLike4* = tuple|object|int
type ObjectLike5* = int|tuple|object
type ObjectLike6* = object|int|tuple

type A = object
  tint: int

doAssert A is ObjectLike4
doAssert A is ObjectLike5
doAssert A is ObjectLike6

doAssert (1,2) is ObjectLike4
doAssert (1,2) is ObjectLike5
doAssert (1,2) is ObjectLike6

doAssert () is ObjectLike4
doAssert () is ObjectLike5
doAssert () is ObjectLike6

var a: A
doAssert a is ObjectLike4
doAssert a is ObjectLike5
doAssert a is ObjectLike6
