##[
Ensures borrowing is rejected when no distinct parameter is present.
]##

block:
  static:
    doAssert not compiles((block:
      proc bogus[T](s: seq[T]): int {.borrow.} =
        s.len
    ))
