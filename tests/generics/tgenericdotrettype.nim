discard """
output: '''string
int
(int, string)
'''
"""

import typetraits

type
  Foo[T, U] = object
    x: T
    y: U

proc bar[T](a: T): T.U =
  echo result.type.name

proc bas(x: auto): x.T =
  echo result.type.name

proc baz(x: Foo): (Foo.T, x.U) =
  echo result.type.name

var
  f: Foo[int, string]
  x = bar f
  z = bas f
  y = baz f

