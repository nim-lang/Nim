discard """
  nimout: '''
()
Sym "b"
()
Sym "a"
()
Sym "b"
()
StmtList
'''
  output: '''
hello
hello again
'''
"""

{.experimental: "callOperator".}

import macros

type Foo[T: proc] = object
  callback: T

macro `()`(foo: Foo, args: varargs[untyped]): untyped =
  result = newCall(newDotExpr(foo, ident"callback"))
  for a in args:
    result.add(a)

var f = Foo[proc()](callback: proc() = echo "hello")
f()
f.callback = proc() = echo "hello again"
f()

let g = Foo[proc (x: int): int](callback: proc (x: int): int = x * 2 + 1)
doAssert g(15) == 31

macro `()`(foo: untyped, args: varargs[untyped]): untyped =
  result = newStmtList()
  echo "()"
  echo foo.treeRepr

let a = 1
let b = 2
let c = 3

a.b(c)
a(b)
(a.b)(c)
