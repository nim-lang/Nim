discard """
  output: "23"
"""

template optslice{a = b + c}(a: untyped{noalias}, b, c: untyped): typed =
  a = b
  inc a, c

var
  x = 12
  y = 10
  z = 13

x = y+z

echo x
