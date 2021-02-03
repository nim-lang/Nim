discard """
  nimout: '''
()
()
()
calling ()
Arglist
  Sym "b"
  Sym "a"
calling .
Arglist
  Sym "a"
  Ident "b"
calling .
Arglist
  Sym "a"
  Ident "b"
  Ident "c"
calling ()
Arglist
  Sym "a"
  Sym "b"
calling ()
Arglist
  Call
    Sym "b"
    Sym "a"
  Sym "c"
'''
"""

{.experimental: "dotOperators".}
{.experimental: "callOperator".}

import macros

block:
  macro `.()`(foo: untyped, args: varargs[untyped]): untyped {.used.} =
    result = newEmptyNode()
    echo ".()"

  macro `()`(foo: untyped, args: varargs[untyped]): untyped =
    result = newEmptyNode()
    echo "()"

  let a = (b: 1)
  let c = 3

  a.b(c)
  a(c)
  (a.b)(c)

macro `()`(args: varargs[untyped]): untyped =
  result = newEmptyNode()
  echo "calling ()"
  echo args.treeRepr

macro `.`(args: varargs[untyped]): untyped =
  result = newEmptyNode()
  echo "calling ."
  echo args.treeRepr

block:
  let a = 1
  let b = 2
  a.b # becomes `()`(a, b)

block:
  let a = 1
  proc b(): int {.used.} = 2
  a.b # becomes `.`(a, b)

block:
  let a = 1
  proc b(x: int): int = x + 1
  let c = 3

  a.b(c) # becomes `.`(a, b, c)
  a(b) # becomes `()`(a, b)
  (a.b)(c) # becomes `()`(a.b, c)
