block:
  type
    InnerInt = distinct seq[int]
    OuterInt = distinct InnerInt

  proc len(s: InnerInt): int {.borrow.}
  proc len(s: OuterInt): int {.borrow.}

  var o: OuterInt
  doAssert o.len == 0
