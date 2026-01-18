##[
This testcase checks that arithmetic operators can be borrowed on distinct types
and that incompatible static parameters do not type-check.
]##

type
  Amount[date: static[int]] = distinct float

proc `+`(x, y: Amount[1]): Amount[1] {.borrow.}
proc `==`(x, y: Amount[1]): bool {.borrow.}

block:
  let total = Amount[1](1.25) + Amount[1](2.5)
  doAssert total == Amount[1](3.75)
  static: doAssert not compiles(Amount[1](1.25) + Amount[100](2.5))
