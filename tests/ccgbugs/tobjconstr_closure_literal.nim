discard """
  matrix: "--mm:refc; --mm:orc"
  ccodecheck: "\\i !@('tyObject_F' [a-zA-Z0-9_]* \\s+ 'T' [0-9]+ '_;')"
"""

# bug #26190: a literal field value cannot alias the iterator environment.
# Construct directly in that environment, without a large stack temporary.
type F = object
  b: array[24576, byte]
  d: int

iterator j(): int {.closure.} =
  var w: F
  w.b[0] = 42
  yield 0
  w = F(d: 0)
  doAssert w.b[0] == 0
  doAssert w.d == 0
  yield 1

let iter = j
doAssert iter() == 0
doAssert iter() == 1
