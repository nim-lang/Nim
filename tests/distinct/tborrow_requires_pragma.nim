# Section: Borrowed proc requires explicit borrow pragma on distinct type.
block:
  type
    Base = object
      value: int
    DistinctBase = distinct Base
    DistinctBaseNoBorrow = distinct Base

  proc bump(b: var Base; delta: int) =
    b.value += delta

  proc bump(b: var DistinctBase; delta: int) {.borrow.}

  var ok = DistinctBase(Base(value: 1))
  ok.bump(2)
  doAssert Base(ok).value == 3

  var noBorrow = DistinctBaseNoBorrow(Base(value: 1))
  doAssert not compiles((block:
    var tmp = noBorrow
    tmp.bump(2)
    true))
