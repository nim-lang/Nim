discard """
  output: '''ok'''
"""

# bug #5638

type X = object
  a_impl: int

proc a(x: X): int =
  x.a_impl

var x: X
assert(not compiles((block:
  x.a = 1
)))

echo "ok"
