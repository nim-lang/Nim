discard """
  disabled: true
"""

type
  A = ref object of RootObj
  B = ref object of A
  C = ref object of B

proc foo[T: A](a: T):int = 1
proc foo[T: B](b: T):int = 2

var c = C()
doAssert foo(c) == 2
