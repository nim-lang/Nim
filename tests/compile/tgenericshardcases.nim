discard """
  file: "tgenericshardcases.nim"
  output: "int\nfloat\nint\nstring"
"""

import typetraits

proc typeNameLen(x: typedesc): int {.compileTime.} =
  result = x.name.len
  
macro selectType(a, b: typedesc): typedesc =
  result = a

type
  Foo[T] = object
    data1: array[high(T), int]
    data2: array[1..typeNameLen(T), selectType(float, string)]

  MyEnum = enum A, B, C,D

var f1: Foo[MyEnum]
var f2: Foo[int8]

static:
  assert high(f1.data1) == D
  assert high(f1.data2) == 6 # length of MyEnum

  assert high(f2.data1) == 127
  assert high(f2.data2) == 4 # length of int8

