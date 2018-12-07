{.experimental: "notnil".}

import tables

type
  A = ref object
    a: float
    b: float

  B = ref object
    refField: A

when false:
  proc e(a: A) = # A is Ref
    echo a.a > 0 # can't deref a: it might be nil  


  proc e2(a: A) =
    echo not a.isNil and a.a > 0

  proc e3(a: A) =
    if a.isNil:
      echo a.a # can't deref a: it is nil
    else:
      echo a.a

  proc e4(a: A, b: int) =
    var a2 = a
    if b == 0:
      a2 = A()
    echo a2.a # can't deref a2: it might be nil


  proc e5(a: A, b: int) =
    if a.isNil:
      echo 0
    else:
      echo a.a

  proc e6(a: A, b: int) =
    var e = a
    if e.isNil:
      e = A()
    echo e.a

  proc e7(a: A) =
    var b = A()
    for i in 0 .. 5:
      echo b.a # can't deref b: it might be nil
      if i == 2:
        b = a
    echo b.a

  # call

  proc f1: A =
    nil

  proc f2 =
    var a = f1()
    echo a.a # can't defef a: it might be nil

  proc f3: A not nil =
    A()

  proc f4 =
    var a = f3()
    echo a.a

  proc f5(a: var A) =
    a = nil

  proc f6 =
    var a = A()
    echo a.a
    f5(a)
    echo a.a # can't deref a: it might be nil

  proc f7(a: A) =
    case a.isNil:
    of true: echo a.a # can't deref a
    of false: echo 0

  proc f8(a: A): A =
    echo result.a # can't deref result

  proc f9: A not nil =
    echo result.a # can't deref result

  proc f10: A not nil = # return value is nil
    discard 

  proc f11(a: int): A not nil = # why does it work?? ah nim adds result
    if a == 0:
      A()
    else:
      A()

  proc f12(a: int): A not nil = # return might be nil
    if a == 0:
      nil
    else:
      A()

  proc f13(a: int): A =
    if a == 0:
      nil
    else:
      A()

  proc f14(a: int): A not nil=
    if a == 0:
      return A()
    else:
      result = A()

  # fields
  proc f15(b: B not nil) =
    echo b.refField.a # can't deref b.refField

  proc f16(b: B not nil) =
    if not b.refField.isNil:
      echo b.refField.a

  proc f17(b: B not nil) =
    if not b.refField.isNil:
      b.refField = nil
    echo b.refField.a # can't deref b.refField

  proc f18(b: B not nil) =
    b.refField = A()
    echo b.refField.a

  # index
  proc f19(a: seq[A]) =
    echo a[0].a # can't deref a[0]

proc f20(a: seq[A]) =
  var b = 1
  if not a[b].isNil:
    b = 0
    echo a[b].a # can't deref a[b]

var a: A
var b = B()
f20(@[a, A()])




