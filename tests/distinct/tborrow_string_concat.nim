block:
  type DistinctString = distinct string

  proc `&`(a, b: DistinctString): DistinctString {.borrow.}
  proc `==`(a, b: DistinctString): bool {.borrow.}

  let a = DistinctString("a")
  let b = DistinctString("b")
  doAssert (a & b) == DistinctString("ab")

block:
  type DistinctStringNoBorrow = distinct string

  let a = DistinctStringNoBorrow("a")
  let b = DistinctStringNoBorrow("b")
  doAssert not compiles(a & b)
