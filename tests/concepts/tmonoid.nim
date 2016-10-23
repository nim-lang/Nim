discard """
  output: '''true'''
"""

# bug #3686

type Monoid = concept x, y
  x + y is type(x)
  type(z(type(x))) is type(x)

proc z(x: typedesc[int]): int = 0

echo(int is Monoid)
