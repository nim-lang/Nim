discard """
  nimout: "array[0..3, int]"
"""

type
  KK[I: static[int]] = object
   x: array[I, int]

proc foo(a: static[string]): KK[a.len] =
  result.x[0] = 12

var x = foo "test"

import typetraits
static: echo x.x.type.name

