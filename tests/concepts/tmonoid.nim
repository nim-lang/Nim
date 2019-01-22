discard """
  output: '''true'''
"""

# bug #3686

type Monoid = concept x, y
  x + y is type(x)
  type(z(type(x))) is type(x)

proc z(x: typedesc[int]): int = 0

echo(int is Monoid)

# https://github.com/nim-lang/Nim/issues/8126
type AdditiveMonoid* = concept x, y, type T
  x + y is T

  # some redundant checks to test an alternative approaches:
  type TT = type(x)
  x + y is type(x)
  x + y is TT

doAssert(1 is AdditiveMonoid)

