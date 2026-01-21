block:
  type
    DistinctArray = distinct array[3, int]

  proc `[]`(a: DistinctArray, i: int): int {.borrow.}
  proc `[]=`(a: var DistinctArray, i: int, v: int) {.borrow.}

  var a: DistinctArray
  a[0] = 5
  doAssert a[0] == 5
