##[
Ensures borrowing fails when no matching parent signature exists.
]##

block:
  static:
    doAssert not compiles((block:
      type D[T] = distinct seq[T]

      proc add[T](s: var D[T], x, y: T) {.borrow.}
    ))
