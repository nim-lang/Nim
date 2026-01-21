block:
  type
    SeqBox[T] = distinct seq[T]

  proc add[T](s: var SeqBox[T], x: T) {.borrow.}

  var s: SeqBox[int]
  s.add(1)
  doAssert seq[int](s) == @[1]
