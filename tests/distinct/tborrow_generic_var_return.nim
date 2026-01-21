##[
Checks borrowed generic procs returning var for distinct sequences.
]##

block:
  type Buf[T] = distinct seq[T]

  proc head[T](s: var seq[T]): var T =
    s[0]

  proc head[T](s: var Buf[T]): var T {.borrow.}

  var b = Buf(@[1, 2, 3])
  head(b) = 99
  doAssert seq[int](b)[0] == 99
