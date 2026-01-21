##[
Checks borrowed generic bracket operators for distinct sequences.
]##

block:
  type Buf[T] = distinct seq[T]

  proc `[]`[T](b: Buf[T], i: int): T {.borrow.}
  proc `[]=`[T](b: var Buf[T], i: int, v: T) {.borrow.}

  proc setFirst[T](b: var Buf[T], v: T) =
    b[0] = v

  var b = Buf(@[1, 2, 3])
  setFirst(b, 42)
  doAssert b[0] == 42
