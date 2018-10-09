discard """
  output: '''
A
A
'''
"""

type
  A[T] = distinct T
  B[T] = distinct T

proc foo[T](x:A[T]) = echo "A"
proc foo[T](x:B[T]) = echo "B"
proc bar(x:A) = echo "A"
proc bar(x:B) = echo "B"

var
  a:A[int]

foo(a) # fine
bar(a) # testdistinct.nim(14, 4) Error: ambiguous call; both testdistinct.bar(x: A) and testdistinct.bar(x: B) match for: (A[system.int])
