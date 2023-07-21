# Cases that used to only work due to weird workarounds in the compiler
# involving not instantiating calls in generic bodies which are removed
# due to breaking statics.
# The issue was that these calls are compiled as regular expressions at
# the generic declaration with unresolved generic parameter types,
# which are special cased in some places in the compiler, but sometimes
# treated like real types.

block:
  type Base10 = object

  func maxLen(T: typedesc[Base10], I: type): int8 =
    when I is uint8:
      3
    elif I is uint16:
      5
    elif I is uint32:
      10
    elif I is uint64:
      20
    else:
      when sizeof(uint) == 4:
        10
      else:
        20
  
  type
    Base10Buf[T: SomeUnsignedInt] = object
      data: array[maxLen(Base10, T), byte]
      len: int8

  var x: Base10Buf[uint32]
  doAssert x.data.len == 10
  var y: Base10Buf[uint16]
  doAssert y.data.len == 5

import typetraits

block thardcases:
  proc typeNameLen(x: typedesc): int {.compileTime.} =
    result = x.name.len
  macro selectType(a, b: typedesc): typedesc =
    result = a

  type
    Foo[T] = object
      data1: array[T.high, int]
      data2: array[typeNameLen(T), float]
      data3: array[0..T.typeNameLen, selectType(float, int)]
  
  type MyEnum = enum A, B, C, D

  var f1: Foo[MyEnum]
  var f2: Foo[int8]

  doAssert high(f1.data1) == 2 # (D = 3) - 1 == 2
  doAssert high(f1.data2) == 5 # (MyEnum.len = 6) - 1 == 5

  doAssert high(f2.data1) == 126 # 127 - 1 == 126
  doAssert high(f2.data2) == 3 # int8.len - 1 == 3

  static:
    doAssert high(f1.data1) == ord(C)
    doAssert high(f1.data2) == 5 # length of MyEnum minus one, because we used T.high

    doAssert high(f2.data1) == 126
    doAssert high(f2.data2) == 3

    doAssert high(f1.data3) == 6 # length of MyEnum
    doAssert high(f2.data3) == 4 # length of int8

    doAssert f2.data3[0] is float

import muninstantiatedgenericcalls

block:
  var x: Leb128Buf[uint32]
  doAssert x.data.len == 5
  var y: Leb128Buf[uint16]
  doAssert y.data.len == 3
