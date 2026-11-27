discard """
  action: "compile"
"""

# #26775: a conversion that involves a range type must not keep the l-value of
# its operand, or a `var` parameter could store a value the range excludes.

type
  R = range[0..5]
  DR = distinct R
  D = distinct int

proc setInt(x: var int) = x = 100
proc setPair(x: var (int, int)) = x = (100, 100)
proc setR(x: var R) = x = 5
proc setD(x: var D) = x = D(7)

var
  r: R = 1
  i = 1
  d = D(1)
  dr = DR(1)
  pair: (R, R) = (1, 1)
  plain: (int, int) = (1, 1)
  nested: ((R, int), int) = ((1, 1), 1)
  named: tuple[a, b: int] = (1, 1)
  distinctPair: (D, D) = (D(1), D(1))

# range <-> base type
doAssert not compiles(setInt(int(r)))
doAssert not compiles(setR(R(i)))
doAssert not compiles(setInt(int(dr)))

# tuples whose element types differ by a range
doAssert not compiles(setPair((int, int)(pair)))
doAssert not compiles(setPair((int, int)(nested[0])))
doAssert not compiles(setPair((R, R)(plain)))

# l-values that were never converted, and conversions that keep their values
doAssert compiles(setR(r))
doAssert compiles(setInt(int(d)))
doAssert compiles(setD(D(i)))
doAssert compiles(setPair((int, int)(named)))
doAssert compiles(setPair((int, int)(distinctPair)))
doAssert compiles(setPair((int, int)(plain)))
