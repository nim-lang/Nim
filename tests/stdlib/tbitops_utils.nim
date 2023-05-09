discard """
  matrix: "--mm:refc; --mm:orc"
"""

import std/private/bitops_utils
import std/assertions

template chk(a, b) =
  let a2 = castToUnsigned(a)
  doAssert a2 == b
  doAssert type(a2) is type(b)
  doAssert type(b) is type(a2)

chk 1'i8, 1'u8
chk -1'i8, 255'u8
chk 1'u8, 1'u8
chk 1'u, 1'u
chk -1, cast[uint](-1)
chk -1'i64, cast[uint64](-1)
