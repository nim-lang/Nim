# Section: Borrowed procs on distinct ref objects access underlying fields.
block:
  type
    RefInner = ref object
      value: int
    RefOuter = distinct RefInner

  proc getValue(r: RefInner): int =
    r.value

  proc getValue(r: RefOuter): int {.borrow.}

  var inner: RefInner
  new(inner)
  inner.value = 42

  let r = RefOuter(inner)
  doAssert r.getValue == 42
