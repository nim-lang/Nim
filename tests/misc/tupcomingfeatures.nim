discard """
  output: '''0 -2 0
0 -2'''
"""

{.this: self.}

type
  Foo = object
    a, b, x: int

proc yay(self: Foo) =
  echo a, " ", b, " ", x

proc footest[T](self: var Foo, a: T) =
  b = 1+a
  yay()

proc nongeneric(self: Foo) =
  echo a, " ", b

var ff: Foo
footest(ff, -3)
ff.nongeneric

{.experimental.}
using
  c: Foo
  x, y: int

proc usesSig(c) =
  echo "yummy"

proc foobar(c, y) =
  echo "yay"
