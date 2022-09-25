{.experimental: "views".}
discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout: '''
t19546.nim(16, 5) Error: array expects two type parameters
t19546.nim(20, 5) Error: sequence expects one type parameter
t19546.nim(24, 5) Error: set expects one type parameter
t19546.nim(27, 3) Error: cannot use sink as a field type
t19546.nim(28, 3) Error: openArray expects one type parameter
t19546.nim(29, 3) Error: lent expects one type parameter
'''
"""
type
  ExampleObj1 = object
    arr: array

type
  ExampleObj2 = object
    arr: seq

type
  ExampleObj3 = object
    arr: set

type A = object
  b: sink
  a: openarray
  c: lent