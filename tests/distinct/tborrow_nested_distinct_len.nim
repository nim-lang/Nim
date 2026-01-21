block:
  type
    Inner[T] = distinct seq[T]
    Outer[T] = distinct Inner[T]

  proc len[T](s: Outer[T]): int {.borrow.}

  var o: Outer[int]
  doAssert o.len == 0
