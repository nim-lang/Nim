# Section: Borrowed set operations are only available to opted-in distinct sets.
block:
  type
    DistinctSet[T] = distinct set[T]
    DistinctSetNoBorrow[T] = distinct set[T]

  proc incl[T](s: var DistinctSet[T], x: T) {.borrow.}
  proc contains[T](s: DistinctSet[T], x: T): bool {.borrow.}

  var s: DistinctSet[char]
  s.incl('a')
  doAssert s.contains('a')

  var sNoBorrow: DistinctSetNoBorrow[char]
  doAssert not compiles(sNoBorrow.incl('a'))
