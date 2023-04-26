type Foo = object
  bar: int

var foo = Foo(bar: 10)
template bar: int = foo.bar
doAssert bar == 10
bar = 15
doAssert bar == 15
var foo2 = Foo(bar: -10)
doAssert bar == 15
# works in generics
proc genericProc[T](x: T): string =
  $(x, bar)
doAssert genericProc(true) == "(true, 15)"
# redefine
template bar: int {.redefine.} = foo2.bar
doAssert bar == -10

block: # subscript
  var bazVal = @[1, 2, 3]
  template baz: seq[int] = bazVal
  doAssert baz[1] == 2
  proc genericProc2[T](x: T): string =
    result = $(x, baz[1])
    baz[1] = 7
  doAssert genericProc2(true) == "(true, 2)"
  doAssert baz[1] == 7
  baz[1] = 14
  doAssert baz[1] == 14

block: # type alias
  template Int2: untyped = int
  let x: Int2 = 123
  proc generic[T](): string =
    template U: untyped = T
    var x: U
    result = $typeof(x)
    doAssert result == $U
    doAssert result == $T
  doAssert generic[int]() == "int"
  doAssert generic[Int2]() == "int"
  doAssert generic[string]() == "string"
  doAssert generic[seq[int]]() == "seq[int]"
  doAssert generic[seq[Int2]]() == "seq[int]"
  discard generic[123]()
  proc genericStatic[X; T: static[X]](): string =
    template U: untyped = T
    result = $U
    doAssert result == $T
  doAssert genericStatic[int, 123]() == "123"
  doAssert genericStatic[Int2, 123]() == "123"
  doAssert genericStatic[(string, bool), ("a", true)]() == "(\"a\", true)"

block: # issue #13515
  template test: bool = true
  # compiles:
  if not test:
    doAssert false
  # does not compile:
  template x =
    if not test:
      doAssert false
  x

import macros

block: # issue #21727
  template debugAnnotation(s: typed): string =
    astToStr s

  macro cpsJump(x: int): untyped =
    result = newLit(debugAnnotation(cpsJump))
  
  doAssert cpsJump(13) == "cpsJump"
