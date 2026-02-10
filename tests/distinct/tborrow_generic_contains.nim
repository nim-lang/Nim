##[
Checks borrowed generic procs over distinct sequences with user-defined logic.
]##

block:
  type List[T] = distinct seq[T]

  proc contains[T](s: seq[T], value: T): bool =
    for item in s:
      if item == value:
        return true
    false

  proc contains[T](s: List[T], value: T): bool {.borrow.}

  # Section: Borrowed `contains` forwards to custom implementation.
  let xs = List(@["a", "b"])
  doAssert xs.contains("b")
  doAssert not xs.contains("c")
