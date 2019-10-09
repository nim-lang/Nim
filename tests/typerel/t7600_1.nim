discard """
errormsg: "type mismatch: got <Thin[system.int]>"
nimout: '''t7600_1.nim(21, 6) Error: type mismatch: got <Thin[system.int]>
but expected one of:
proc test[T](x: Paper[T])
  first type mismatch at position: 1
  required type for x: Paper[test.T]
  but expression 'tn' is of type: Thin[system.int]

expression: test tn'''
"""

type
  Paper[T] = ref object of RootObj
    thickness: T
  Thin[T]  = object of Paper[T]

proc test[T](x: Paper[T]) = discard

var tn = Thin[int]()
test tn
