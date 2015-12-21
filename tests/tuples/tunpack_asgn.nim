discard """
  output: '''2 4
4
2 0'''
"""

proc foobar(): (int, int) = (2, 4)

# test within a proc:
proc pp(x: var int) =
  var y: int
  (y, x) = foobar()

template pt(x) =
  var y: int
  (x, y) = foobar()

# test within a generic:
proc pg[T](x, y: var T) =
  pt(x)

# test as a top level statement:
var x, y, a, b: int
(x, y) = fooBar()

echo x, " ", y

pp(a)
echo a

pg(a, b)
echo a, " ", b
