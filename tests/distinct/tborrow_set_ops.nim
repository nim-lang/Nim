block:
  type
    DistinctSet[T] = distinct set[T]

  proc incl[T](s: var DistinctSet[T], x: T) {.borrow.}
  proc contains[T](s: DistinctSet[T], x: T): bool {.borrow.}

  var s: DistinctSet[char]
  s.incl('a')
  doAssert s.contains('a')
