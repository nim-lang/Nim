discard """
  output: "42\n42"
"""

type
  Foo[N: static[int]] = object

proc foo[N](x: Foo[N]) =
  let n = N
  echo N
  echo n

var f1: Foo[42]
f1.foo
