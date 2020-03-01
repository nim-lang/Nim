discard """
nimout: "OK"
output: "OK"
"""

proc testUnsignedOps() =
  let a: int8 = -128
  let b: int8 = 127

  doAssert b +% 1 == -128
  doAssert b -% -1 == -128
  doAssert b *% 2 == -2
  doAssert a /% 4 == 32
  doAssert a %% 7 == 2
  echo "OK"

testUnsignedOps()
static:
  testUnsignedOps()
