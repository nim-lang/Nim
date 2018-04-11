discard """
  output: "A\nB\nC\n::\nX\nY\nZ"
"""

type TAlphabet = enum
  A, B, C

type TAlphabetWithHoles = enum
  X, Y, Z=9

proc get_values(): seq[string] =
  result = @[]
  for c in TAlphabet: # items implicit invocation
    result.add($c)
  result.add("::")
  for c in TAlphabetWithHoles: # items implicit invocation
    result.add($c)

const COMPTIME_VALUES = get_values()
let RUNTIME_VALUES = get_values()
for i, cvalue in COMPTIME_VALUES:
  doAssert(cvalue == RUNTIME_VALUES[i])
  echo cvalue

doAssert(TAlphabet.len == 3)
doAssert(TAlphabetWithHoles.len == 3)
static:
  doAssert(TAlphabet.len == 3)
  doAssert(TAlphabetWithHoles.len == 3)
