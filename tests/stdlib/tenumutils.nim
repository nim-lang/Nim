discard """
  targets: "c js"
"""

import std/enumutils
from std/sequtils import toSeq

template main =
  block: # items
    type A = enum a0 = 2, a1 = 4, a2
    type B[T] = enum b0 = 2, b1 = 4
    assert A.toSeq == [a0, a1, a2]
    assert B[float].toSeq == [B[float].b0, B[float].b1]

static: main()
main()
