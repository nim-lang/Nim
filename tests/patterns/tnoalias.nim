discard """
  output: "23"
"""

template optslice{a = b + c}(a: expr{noalias}, b, c: expr): stmt =
  a = b
  inc a, c

var
  x = 12
  y = 10
  z = 13

x = y+z

echo x
