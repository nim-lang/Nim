discard """
  output: '''
foo
C
3.14
foo
3.14
3.14
'''
"""

type
  V = enum
    A, B, C
  X = object
    f0: string
    case f1: V
    of A: f2: string
    of B: discard
    of C: f3: float

var obj = X(f0: "foo", f1: C, f3: 3.14)

block:
  echo obj.f0
  echo obj.f1
  doAssertRaises(FieldDefect): echo obj.f2
  echo obj.f3

block:
  let a0 = addr(obj.f0)
  echo a0[]
  # let a1 = unsafeAddr(obj.f1)
  # echo a1[]
  doAssertRaises(FieldDefect):
    let a2 = addr(obj.f2)
    echo a2[]
  let a3 = addr(obj.f3)
  echo a3[]

# Prevent double evaluation of LHS
block:
  var flag = false
  proc wrap(x: X): X =
    doAssert flag == false
    flag = true
    result = x
  echo wrap(obj).f3
