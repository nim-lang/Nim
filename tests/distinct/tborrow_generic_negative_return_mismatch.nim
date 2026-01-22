##[
Ensures borrowing fails on return type mismatch.
]##

block:
  # Section: Borrowed overload must match return type of base proc.
  static:
    doAssert not compiles((block:
      type D[T] = distinct seq[T]

      proc base[T](s: seq[T]): int =
        s.len

      proc base[T](s: D[T]): string {.borrow.}
    ))
