discard """
  errormsg: "undeclared identifier: 'x'"
"""

var x: int
# bug #21231
template f(y: untyped) = echo y.x
for i in 1 .. 10:
  x = i
  f(system)
