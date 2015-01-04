discard """
  output: '''61, 125
89'''
"""

proc `^` (a, b: int): int =
  result = 1
  for i in 1..b: result = result * a

var m = (0, 5)
var n = (56, 3)

m = (n[0] + m[1], m[1] ^ n[1])

echo m[0], ", ", m[1]

var x = (bar: 38)
x = (foo: 89)
echo x[0]
