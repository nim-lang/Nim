discard """
  action: run
"""

block:
  var x = (a: 5, b: 1)
  x = (3 * x.a + 2 * x.b, x.a + x.b)
  doAssert x.a == 17
  doAssert x.b == 6
block:
  # Transformation of a tuple constructor with named arguments
  var x = (a: 5, b: 1)
  x = (a: 3 * x.a + 2 * x.b, b: x.a + x.b)
  doAssert x.a == 17
  doAssert x.b == 6
