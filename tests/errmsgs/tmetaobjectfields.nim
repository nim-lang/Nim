discard """
  cmd: "nim check --hints:off $file"
  action: "reject"
  nimout: '''
tmetaobjectfields.nim(20, 5) Error: 'array' is not a concrete type
tmetaobjectfields.nim(24, 5) Error: 'seq' is not a concrete type
tmetaobjectfields.nim(28, 5) Error: 'set' is not a concrete type
tmetaobjectfields.nim(31, 3) Error: 'sink' is not a concrete type
tmetaobjectfields.nim(33, 3) Error: 'lent' is not a concrete type
tmetaobjectfields.nim(50, 16) Error: 'seq' is not a concrete type
'''
"""


# bug #6982
# bug #19546
# bug #23531
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
  # a: openarray
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
