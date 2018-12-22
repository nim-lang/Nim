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

e(a)

