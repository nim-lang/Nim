##[
This testcase checks that length can be borrowed on a distinct seq.
]##

type
  HeapQueue = distinct seq[int]
  HeapQueueNoBorrow = distinct seq[int]

proc len*(h: HeapQueue): int {.borrow.}

block:
  var h = HeapQueue(@[1, 2, 3])
  doAssert h.len == 3

  var hNoBorrow = HeapQueueNoBorrow(@[1, 2, 3])
  doAssert not compiles(hNoBorrow.len)
