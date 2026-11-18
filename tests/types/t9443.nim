# bug #9443: `x is var` for a `var` parameter
var x: int
proc f(a: var int) =
  doAssert a is var
  doAssert a is var int
  doAssert a isnot var float
  doAssert a is int
f(x)

proc g[T](a: var T, b: T) =
  doAssert a is var
  doAssert b isnot var
g(x, 1)

var y: ref int
doAssert y is ref
