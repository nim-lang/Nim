import macros

{.experimental: "callOperator".}

type Foo[T: proc] = object
  callback: T

macro `()`(foo: Foo, args: varargs[untyped]): untyped =
  result = newCall(newDotExpr(foo, ident"callback"))
  for a in args:
    result.add(a)

var f1Calls = 0
var f = Foo[proc()](callback: proc() = inc f1Calls)
doAssert f1Calls == 0
f()
doAssert f1Calls == 1
var f2Calls = 0
f.callback = proc() = inc f2Calls
doAssert f2Calls == 0
f()
doAssert f2Calls == 1

let g = Foo[proc (x: int): int](callback: proc (x: int): int = x * 2 + 1)
doAssert g(15) == 31

proc `()`(args: varargs[string]): string =
  result = "("
  for a in args: result.add(a)
  result.add(')')

let a = "1"
let b = "2"
let c = "3"

doAssert a(b) == "(12)"
doAssert a.b(c) == `()`(b, a, c)
doAssert (a.b)(c) == `()`(a.b, c)
doAssert `()`(a.b, c) == `()`(`()`(b, a), c)
