discard """
  output: '''a 1 b 2 x @[3, 4, 5] y 6 z 7
yay
12
'''
"""

proc test(a, b: int, x: varargs[int]; y, z: int) =
  echo "a ", a, " b ", b, " x ", @x, " y ", y, " z ", z

test 1, 2, 3, 4, 5, 6, 7

# XXX maybe this should also work with ``varargs[untyped]``
template takesBlockA(a, b: untyped; x: varargs[typed]; blck: untyped): untyped =
  blck
  echo a, b

takesBlockA 1, 2, "some", 0.90, "random stuff":
  echo "yay"
