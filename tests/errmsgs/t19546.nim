discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout: '''
t19546.nim(12, 5) Error: array expects two type parameters
t19546.nim(16, 5) Error: sequence expects one type parameter
t19546.nim(20, 5) Error: set expects one type parameter
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
