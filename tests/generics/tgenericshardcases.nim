discard """
  file: "tgenericshardcases.nim"
  output: "2\n5\n126\n3"
"""

import typetraits

proc typeNameLen(x: typedesc): int {.compileTime.} =
  result = x.name.len
  
macro selectType(a, b: typedesc): typedesc =
  result = a

type
  Foo[T] = object
    data1: array[T.high, int]
    data2: array[typeNameLen(T), float]
    data3: array[0..T.typeNameLen, selectType(float, int)]

  MyEnum = enum A, B, C, D

var f1: Foo[MyEnum]
var f2: Foo[int8]

echo high(f1.data1) # (D = 3) - 1 == 2
echo high(f1.data2) # (MyEnum.len = 6) - 1 == 5

echo high(f2.data1) # 127 - 1 == 126
echo high(f2.data2) # int8.len - 1 == 3

static:
  assert high(f1.data1) == ord(C)
  assert high(f1.data2) == 5 # length of MyEnum minus one, because we used T.high

  assert high(f2.data1) == 126
  assert high(f2.data2) == 3 

  assert high(f1.data3) == 6 # length of MyEnum
  assert high(f2.data3) == 4 # length of int8

  assert f2.data3[0] is float

