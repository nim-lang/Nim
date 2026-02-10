##[
Ensures borrowing is rejected when no distinct parameter is present.
]##

block:
  # Section: Borrowed proc requires a distinct parameter in its signature.
  static:
    doAssert not compiles((block:
      proc bogus[T](s: seq[T]): int {.borrow.} =
        s.len
    ))
