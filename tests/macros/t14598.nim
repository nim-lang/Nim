discard """
  nimout: '''
let a = 0x7F800000'f32
let b = 0xFFF0000000000000'f64
let c = 0x7FF0000000000000'f64
'''
  output: "inf -inf inf true"
"""

# bug #14598: `repr` of an infinite or NaN float literal can be parsed again
import std/macros
macro mdbg(a): untyped =
  echo a.repr
  parseStmt(a.repr)
mdbg:
  let a = 1e1000000'f32
  let b = -1e1000000
  let c = 1e1000000'f64
macro nanRoundTrip(): untyped = parseExpr(repr(newLit(NaN)))
let d = nanRoundTrip()
echo a, " ", b, " ", c, " ", d != d
