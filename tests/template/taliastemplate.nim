block: # without {.alias.}
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
    template Int: untyped = int
    let x: Int = 123
    proc generic[T](): string =
      template U: untyped = T
      result = $U
      doAssert result == $T
    doAssert generic[int]() == "int"
    doAssert generic[string]() == "string"
    doAssert generic[seq[int]]() == "seq[int]"
    discard generic[123]()
    proc genericStatic[X; T: static[X]](): string =
      template U: untyped = T
      result = $U
      doAssert result == $T
    doAssert genericStatic[int, 123]() == "123"
    doAssert genericStatic[(string, bool), ("a", true)]() == "(\"a\", true)"

block: # {.alias.}
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
  
  block: # subscript
    var bazVal = @[1, 2, 3]
    template baz: seq[int] {.alias.} = bazVal
    doAssert baz[1] == 2
    proc genericProc2[T](x: T): string =
      result = $(x, baz[1])
      baz[1] = 7
    doAssert genericProc2(true) == "(true, 2)"
    doAssert baz[1] == 7
    baz[1] = 14
    doAssert baz[1] == 14

  block: # type alias
    template Int: untyped {.alias.} = int
    let x: Int = 123
    proc generic[T](): string =
      template U: untyped {.alias.} = T
      result = $U
      doAssert result == $T
    doAssert generic[int]() == "int"
    doAssert generic[string]() == "string"
    doAssert generic[seq[int]]() == "seq[int]"
    discard generic[123]()
    proc genericStatic[X; T: static[X]](): string =
      template U: untyped {.alias.} = T
      result = $U
      doAssert result == $T
    doAssert genericStatic[int, 123]() == "123"
    doAssert genericStatic[(string, bool), ("a", true)]() == "(\"a\", true)"

  block: # inside template
    template foo =
      doAssert minus(bar) == 10
      doAssert minus(bar, minus(bar)) == -20
      doAssert not compiles(minus())
      template plus: untyped {.alias.} = `+`
      doAssert plus(bar) == -10
      doAssert plus(bar, plus(bar)) == -20
      doAssert not compiles(plus())
    foo()
    block:
      foo()
