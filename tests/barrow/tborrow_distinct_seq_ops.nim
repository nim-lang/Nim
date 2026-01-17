##[
This testcase checks that distinct seq types are in fact distinct.
]##

type
  DistinctSeqA = distinct seq[int]
  DistinctSeqB = distinct seq[int]

proc `&`*(a, b: DistinctSeqA): DistinctSeqA {.borrow.}
proc `&`*(a, b: DistinctSeqB): DistinctSeqB {.borrow.}
proc `==`*(a, b: DistinctSeqA): bool {.borrow.}
proc `==`*(a, b: DistinctSeqB): bool {.borrow.}

block:
  var a0 = DistinctSeqA(@[1, 2, 3])
  var a1 = DistinctSeqA(@[4, 5, 6])
  doAssert (a0 & a1) == DistinctSeqA(@[1, 2, 3, 4, 5, 6])

  var b0 = DistinctSeqB(@[1, 2, 3])
  var b1 = DistinctSeqB(@[4, 5, 6])
  doAssert (b0 & b1) == DistinctSeqB(@[1, 2, 3, 4, 5, 6])

  doAssert not compiles(a0 & b1)

  var c = @[1, 2, 3]
  doAssert not compiles(c & b1)
