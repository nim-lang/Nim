discard """
  output: '''42'''
"""

type
  Foo[N: static[int]] = object

proc foo[N](x: Foo[N]) =
  echo N

var f1: Foo[42]
f1.foo
