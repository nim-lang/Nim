import macros

block:
  template `.()`(foo: int, args: varargs[untyped]): untyped {.used.} =
    ".()"

  template `()`(foo: int, args: varargs[untyped]): untyped =
    "()"

  let a = (b: 1)
  let c = 3

  {.push experimental: "callOperator".}
  {.push experimental: "dotOperators".}
  doAssert a.b(c) == "()"
  doAssert not compiles(a(c))
  doAssert (a.b)(c) == "()"
  {.pop.}
  {.pop.}

macro `()`(args: varargs[typed]): untyped =
  result = newLit("() " & args.treeRepr)

macro `.`(args: varargs[typed]): untyped =
  result = newLit(". " & args.treeRepr)

{.experimental: "dotOperators".}
{.experimental: "callOperator".}

block:
  let a = 1
  let b = 2
  doAssert a.b == `()`(b, a)

block:
  let a = 1
  proc b(): int {.used.} = 2
  doAssert a.b == `.`(a, b)

block:
  let a = 1
  proc b(x: int): int = x + 1
  let c = 3

  doAssert a.b(c) == `.`(a, b, c)
  doAssert a(b) == `()`(a, b)
  doAssert (a.b)(c) == `()`(a.b, c)
  doAssert a.b == b(a)
