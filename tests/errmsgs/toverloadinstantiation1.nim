discard """
  action: "reject"
  matrix: "--hints:off -d:testsConciseTypeMismatch"
  nimoutFull: true
  nimout: '''
toverloadinstantiation1.nim(28, 6) Error: type mismatch
Expression: foo([1, 2, 3, 4])
  [1] [1, 2, 3, 4]: array[0..3, int]

Expected one of (first mismatch at [position]):
[1] proc foo[I: static int](x: array[double(I), int])
  instantiation error at toverloadinstantiation1.nim(27, 42):
  cannot infer the value of the static param 'I'

'''
"""

proc double(x: int): int = x * 2

block: # this not erroring is checked by nimoutFull
  proc foo[I: static int](x: array[I, int]) = discard
  proc foo[I: static int](x: array[double(I), int]) = discard
  foo([1, 2, 3, 4])
  foo[2]([1, 2, 3, 4]) # this picks double overload

block: 
  proc foo[I: static int](x: array[double(I), int]) = discard
  foo([1, 2, 3, 4])
