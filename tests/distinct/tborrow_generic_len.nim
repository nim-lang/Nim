##[
Checks borrowed generic len for distinct sequences.
]##

block:
  type MySeq[T] = distinct seq[T]

  proc len[T](s: MySeq[T]): int {.borrow.}

  proc size[T](s: MySeq[T]): int =
    s.len

  var items = MySeq(@[1, 2, 3])
  doAssert size(items) == 3
