discard """
  joinable: false
"""

type VectorSpace[K] = concept x, y
  x + y is type(x)
  zero(type(x)) is type(x)
  -x is type(x)
  x - y is type(x)
  var k: K
  k * x is type(x)

proc zero(T: typedesc): T = 0

static:
  assert float is VectorSpace[float]
  # assert float is VectorSpace[int]
  # assert int is VectorSpace

