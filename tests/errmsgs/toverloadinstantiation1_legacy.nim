discard """
  action: "reject"
  matrix: "--hints:off"
  nimoutFull: true
  nimout: '''
toverloadinstantiation1_legacy.nim(29, 6) Error: type mismatch: got <array[0..3, int]>
but expected one of:
proc foo[I: static int](x: array[double(I), int])
  first type mismatch at position: 1
  required type for x: array[0..static(pred(double(I))), int]
  but expression '[1, 2, 3, 4]' is of type: array[0..3, int]
  instantiation error at toverloadinstantiation1_legacy.nim(28, 42):
  cannot infer the value of the static param 'I'

expression: foo([1, 2, 3, 4])
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
