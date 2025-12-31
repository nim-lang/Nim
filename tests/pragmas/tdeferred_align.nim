discard """
  targets: "c cpp"
"""

# Type-level align with generic param (native types)
type
  GenericAligned[T] {.align: alignof(T).} = object
    value: T

  Container[T] = object
    data {.align: alignof(T).}: T

  MultiParam[T, U] {.align: alignof(T).} = object
    field1 {.align: alignof(U).}: U
    field2 {.align: alignof(T).}: T

# Test instantiation
var alignedInt: GenericAligned[int]
alignedInt.value = 42
doAssert alignedInt.value == 42

var alignedChar: GenericAligned[char]
alignedChar.value = 'x'
doAssert alignedChar.value == 'x'

var containerInt: Container[int]
containerInt.data = 123
doAssert containerInt.data == 123

var containerInt64: Container[int64]
containerInt64.data = 9876543210'i64
doAssert containerInt64.data == 9876543210'i64

var multi: MultiParam[int, char]
multi.field1 = 'a'
multi.field2 = 999
doAssert multi.field1 == 'a'
doAssert multi.field2 == 999

# Basic alignment verification
static:
  doAssert alignof(GenericAligned[int]) >= alignof(int)
  doAssert alignof(GenericAligned[int64]) >= alignof(int64)
  doAssert alignof(MultiParam[int64, char]) >= alignof(int64)

# Nested generic contexts
type
  Nested[T] = object
    inner {.align: alignof(T).}: T

  DoubleNested[T, U] = object
    level1 {.align: alignof(T).}: Nested[U]
    level2 {.align: alignof(U).}: T

var nestedIntFloat: DoubleNested[int, float]
nestedIntFloat.level1.inner = 3.14
nestedIntFloat.level2 = 42
doAssert nestedIntFloat.level1.inner == 3.14
doAssert nestedIntFloat.level2 == 42

# Multiple fields with different alignments
type
  MultiField[T] = object
    a {.align: alignof(T).}: T
    b {.align: alignof(int).}: int
    c {.align: alignof(T).}: T

var multiFieldChar: MultiField[char]
multiFieldChar.a = 'x'
multiFieldChar.b = 100
multiFieldChar.c = 'y'
doAssert multiFieldChar.a == 'x'
doAssert multiFieldChar.b == 100
doAssert multiFieldChar.c == 'y'

var multiFieldInt64: MultiField[int64]
multiFieldInt64.a = 1'i64
multiFieldInt64.b = 2
multiFieldInt64.c = 3'i64
doAssert multiFieldInt64.a == 1'i64
doAssert multiFieldInt64.b == 2
doAssert multiFieldInt64.c == 3'i64

# Test with array types
type
  ArrayAligned[T] = object
    data {.align: alignof(T).}: array[10, T]

var arrayAlignedInt: ArrayAligned[int]
arrayAlignedInt.data[0] = 1
arrayAlignedInt.data[9] = 10
doAssert arrayAlignedInt.data[0] == 1
doAssert arrayAlignedInt.data[9] == 10

# Test with expressions
const CacheLine = 64

type
  CacheAligned[T] {.align: (if alignof(T) > CacheLine: alignof(T) else: CacheLine).} = object
    value: T

var cacheInt: CacheAligned[int]
cacheInt.value = 777
doAssert cacheInt.value == 777
doAssert alignof(CacheAligned[int]) >= CacheLine

type
  Aligned128 {.align: 128.} = object
    data: array[64, byte]

var cacheLarge: CacheAligned[Aligned128]
cacheLarge.value.data[0] = 1
doAssert cacheLarge.value.data[0] == 1
doAssert alignof(CacheAligned[Aligned128]) >= 128
