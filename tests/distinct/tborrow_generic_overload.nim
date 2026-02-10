##[
Checks borrowed generic overload resolution on distinct seq/set types.
]##

block:
  type DSeq[T] = distinct seq[T]
  type DSet[T] = distinct set[T]

  proc sum[T](s: seq[T]): int =
    s.len

  proc sum[T](s: set[T]): int =
    100 + s.len

  proc sum[T](s: DSeq[T]): int {.borrow.}
  proc sum[T](s: DSet[T]): int {.borrow.}

  # Section: Borrowed overload chooses seq vs set implementation.
  let xs = DSeq(@[1, 2, 3])
  let ys = DSet({1, 2})

  doAssert xs.sum == 3
  doAssert ys.sum == 102
