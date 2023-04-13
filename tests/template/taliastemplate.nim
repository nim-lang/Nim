type Foo = object
  bar: int

var foo = Foo(bar: 10)
template bar: int {.alias.} = foo.bar
doAssert bar == 10
bar = 15
doAssert bar == 15
var foo2 = Foo(bar: -10)
doAssert bar == 15
# works in generics
proc genericProc[T](x: T): string =
  $(x, bar)
doAssert genericProc(true) == "(true, 15)"
# calling an alias
template minus: untyped {.alias.} = `-`
doAssert minus(bar) == -15
doAssert minus(bar, minus(bar)) == 30
doAssert not compiles(minus())
# works in generics
proc genericProc2[T](x: T): string =
  $(x, minus(x))
doAssert genericProc2(5) == "(5, -5)"
# redefine
template bar: int {.alias, redefine.} = foo2.bar
doAssert minus(bar) == 10
block:
  # cannot use if overloaded
  template minus(a, b, c): untyped = a - b - c
  doAssert minus(3, 5, 8) == -10
  doAssert not compiles(minus(1))
