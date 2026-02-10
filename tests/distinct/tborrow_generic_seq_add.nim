# Section: Borrowed generic `add` works only for types declaring borrow.
block:
  type
    SeqBox[T] = distinct seq[T]
    SeqBoxNoBorrow[T] = distinct seq[T]

  proc add[T](s: var SeqBox[T], x: T) {.borrow.}

  var s: SeqBox[int]
  s.add(1)
  doAssert seq[int](s) == @[1]

  var sNoBorrow: SeqBoxNoBorrow[int]
  doAssert not compiles(sNoBorrow.add(1))
