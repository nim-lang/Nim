##[
Checks borrowed generic accessors for distinct ref object wrappers.
]##

block:
  type Box[T] = ref object
    val: T

  proc getVal[T](b: Box[T]): T =
    b.val

  type DBox[T] = distinct Box[T]

  proc getVal[T](b: DBox[T]): T {.borrow.}

  var b = DBox[int](Box[int](val: 7))
  doAssert b.getVal == 7
