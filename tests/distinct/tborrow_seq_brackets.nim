##[
This testcase checks that bracket operators can be borrowed on distinct seqs.
]##

type
  DistinctSeq = distinct seq[int]
  DistinctSeqAlt = distinct seq[int]

proc `[]`*(s: DistinctSeq, i: int): int {.borrow.}
proc `[]`*(s: var DistinctSeq, i: int): var int {.borrow.}
proc `[]=`*(s: var DistinctSeq, i: int, val: int) {.borrow.}

# Section: Borrowed brackets allow reads/writes on opted-in distinct seq.
var s = DistinctSeq(@[1, 2, 3])
var t: DistinctSeqAlt

doAssert s[1] == 2
s[1] = 5

doAssert s[1] == 5
doAssert not compiles(t[0] == 0)
