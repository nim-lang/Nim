discard """
  output: '''0
123'''
"""

# bug #3498

template defaultOf[T](t: T): expr = (var d: T; d)

echo defaultOf(1) #<- excpected 0

# assignment using template

template tassign[T](x: var seq[T]) =
  x = @[1, 2, 3]

var y: seq[int]
tassign(y) #<- x is expected = @[1, 2, 3]
tassign(y)

echo y[0], y[1], y[2]
