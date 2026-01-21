##[
Checks borrowed generic accessors for distinct object wrappers.
]##

block:
  type SomeParent[T] = object
    val: T

  proc getVal[T](sp: SomeParent[T]): T =
    sp.val

  type DistinctChild[T] = distinct SomeParent[T]

  proc getVal[T](dc: DistinctChild[T]): T {.borrow.}

  var concrete: DistinctChild[int]
  doAssert concrete.getVal() == 0
