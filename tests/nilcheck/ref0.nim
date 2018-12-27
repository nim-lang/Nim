discard """
  cmd: "nim check $file"
  errormsg: ""
  nimout: '''
  ref0.nim(65, 8) Error: can't deref a it might be nil
   param with nilable type on line 64:7
  ref0.nim(72, 10) Error: can't deref a it is nil
    isNil on line 71:6
  ref0.nim(80, 8) Error: can't deref a2 it might be nil
    assigns a value which might be nil on line 77:6
  ref0.nim(97, 10) Error: can't deref b it might be nil
    assigns a value which might be nil on line 95:6
  ref0.nim(100, 8) Error: can't deref b it might be nil
    assigns a value which might be nil on line 95:6
  ref0.nim(107, 8) Error: can't deref a it might be nil
    assigns a value which might be nil on line 106:6
  ref0.nim(123, 8) Error: can't deref a it might be nil
    passes it as a var arg which might change to nil on line 122:4
  ref0.nim(129, 17) Error: can't deref a it is nil
    isNil on line 128:8
  ref0.nim(133, 8) Error: can't deref result it is nil
    it is nil by default on line 132
  ref0.nim(136, 8) Error: can't deref result it is nil
    it is nil by default on line 135:0
  ref0.nim(138, 1) Error: return value is nil
  ref0.nim(147, 1) Error: return value might be nil
  ref0.nim(174, 9) Error: can't deref b.refField it might be nil
    it has ref type on line 174
  '''





















"""
import tables

type
  A* = ref object
    a*: float
    b*: float

  B* = ref object
    refField*: A

var a*: A

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
  echo a.a



proc f7(a: A) =
  case a.isNil:
  of true: echo a.a
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

when false:
  proc f17(b: B not nil) =
    if not b.refField.isNil:
      b.refField = nil
    echo b.refField.a # can't deref b.refField

  proc f18(b: B not nil) =
    b.refField = A()
    echo b.refField.a

e(a)


