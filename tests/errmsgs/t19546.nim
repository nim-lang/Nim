{.experimental: "views".}
discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout: '''
t19546.nim(17, 5) Error: 'array' is not a concrete type
t19546.nim(21, 5) Error: 'seq' is not a concrete type
t19546.nim(25, 5) Error: 'set' is not a concrete type
t19546.nim(28, 3) Error: cannot use 'sink' as a field type
t19546.nim(29, 3) Error: 'openArray' is not a concrete type
t19546.nim(30, 3) Error: 'lent' is not a concrete type
t19546.nim(47, 16) Error: 'seq' is not a concrete type
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

type PropertyKind = enum
  tInt,
  tFloat,
  tBool,
  tString,
  tArray

type
  Property = ref PropertyObj
  PropertyObj = object
    case kind: PropertyKind
    of tInt: intValue: int
    of tFloat: floatValue: float
    of tBool: boolValue: bool
    of tString: stringValue: string
    of tArray: arrayValue: seq
