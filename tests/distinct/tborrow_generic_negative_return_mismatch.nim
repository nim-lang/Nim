##[
Ensures borrowing fails on return type mismatch.
]##

block:
  static:
    doAssert not compiles((block:
      type D[T] = distinct seq[T]

      proc base[T](s: seq[T]): int =
        s.len

      proc base[T](s: D[T]): string {.borrow.}
    ))
