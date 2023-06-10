discard """
  matrix: "; -d:useUntyped; --experimental:genericBodyInstantiateCalls -d:useUntyped"
"""

# Cases that work due to weird workarounds in the compiler involving not
# instantiating calls in generic bodies which are removed with
# --experimental:instantiatedGenericCalls due to breaking statics.
# Ideally these work in the future, with the same behavior as the relevant
# parts being wrapped in an `untyped` call. The issue is that these calls are
# compiled as regular expressions at the generic declaration with
# unresolved generic parameter types, which are special cased in some
# places in the compiler, but sometimes treated like real types.
# It's hard to fix this without losing some information (by turning every call
# in `range` into `nkStaticExpr`) or compiler performance (by checking if
# the expression compiles then using `nkStaticExpr`, which does not always
# work since the compiler can wrongly treat unresolved generic params as
# real types).

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
  
  when not defined(useUntyped):
    type
      Base10Buf[T: SomeUnsignedInt] = object
        data: array[maxLen(Base10, T), byte]
          # workaround for experimental switch is `untyped maxLen(Base10, T)`
        len: int8
  else:
    type
      Base10Buf[T: SomeUnsignedInt] = object
        data: array[untyped maxLen(Base10, T), byte]
          # test workaround
        len: int8
  
  var x: Base10Buf[uint32]
  doAssert x.data.len == 10
  var y: Base10Buf[uint16]
  doAssert y.data.len == 5

import typetraits

block thardcases:
  proc typeNameLen(x: typedesc): int =
    result = x.name.len
  macro selectType(a, b: typedesc): typedesc =
    result = a

  when not defined(useUntyped):
    type
      Foo[T] = object
        data1: array[T.high, int]
        data2: array[typeNameLen(T), float]
          # workaround for experimental switch is `untyped typeNameLen(T)`
        data3: array[0..T.typeNameLen, selectType(float, int)]
          # workaround for experimental switch is `untyped T.typeNameLen`
  else:
    type
      Foo[T] = object
        data1: array[T.high, int]
        data2: array[untyped typeNameLen(T), float]
          # test workaround
        data3: array[0..untyped T.typeNameLen, selectType(float, int)]
          # test workaround
  
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
