import macros

type
  MyType = object
    a : int
    b : string

  RefObject = ref object
    x: int

  RegularObject = object
    x: int

  ObjectRefAlias = ref RegularObject

macro test_newLit_MyType: untyped =
  let mt = MyType(a: 123, b:"foobar")
  result = newLit(mt)

doAssert test_newLit_MyType == MyType(a: 123, b:"foobar")

macro test_newLit_array: untyped =
  let arr = [1,2,3,4,5]
  result = newLit(arr)

doAssert test_newLit_array == [1,2,3,4,5]

macro test_newLit_seq_int: untyped =
  let s: seq[int] = @[1,2,3,4,5]
  result = newLit(s)

block:
  let tmp: seq[int] = test_newLit_seq_int
  doAssert tmp == @[1,2,3,4,5]

macro test_newLit_seq_int8: untyped =
  let s: seq[int8] = @[1'i8,2,3,4,5]
  result = newLit(s)

block:
  let tmp: seq[int8] = test_newLit_seq_int8
  doAssert tmp == @[1'i8,2,3,4,5]

macro test_newLit_seq_int16: untyped =
  let s: seq[int16] = @[1'i16,2,3,4,5]
  result = newLit(s)

block:
  let tmp: seq[int16] = test_newLit_seq_int16
  doAssert tmp == @[1'i16,2,3,4,5]

macro test_newLit_seq_int32: untyped =
  let s: seq[int32] = @[1'i32,2,3,4,5]
  result = newLit(s)

block:
  let tmp: seq[int32] = test_newLit_seq_int32
  doAssert tmp == @[1'i32,2,3,4,5]

macro test_newLit_seq_int64: untyped =
  let s: seq[int64] = @[1'i64,2,3,4,5]
  result = newLit(s)

block:
  let tmp: seq[int64] = test_newLit_seq_int64
  doAssert tmp == @[1'i64,2,3,4,5]

macro test_newLit_seq_uint: untyped =
  let s: seq[uint] = @[1u,2,3,4,5]
  result = newLit(s)

block:
  let tmp: seq[uint] = test_newLit_seq_uint
  doAssert tmp == @[1u,2,3,4,5]

macro test_newLit_seq_uint8: untyped =
  let s: seq[uint8] = @[1'u8,2,3,4,5]
  result = newLit(s)

block:
  let tmp: seq[uint8] = test_newLit_seq_uint8
  doAssert tmp == @[1'u8,2,3,4,5]

macro test_newLit_seq_uint16: untyped =
  let s: seq[uint16] = @[1'u16,2,3,4,5]
  result = newLit(s)

block:
  let tmp: seq[uint16] = test_newLit_seq_uint16
  doAssert tmp == @[1'u16,2,3,4,5]

macro test_newLit_seq_uint32: untyped =
  let s: seq[uint32] = @[1'u32,2,3,4,5]
  result = newLit(s)

block:
  let tmp: seq[uint32] = test_newLit_seq_uint32
  doAssert tmp == @[1'u32,2,3,4,5]

macro test_newLit_seq_uint64: untyped =
  let s: seq[uint64] = @[1'u64,2,3,4,5]
  result = newLit(s)

block:
  let tmp: seq[uint64] = test_newLit_seq_uint64
  doAssert tmp == @[1'u64,2,3,4,5]

macro test_newLit_seq_float: untyped =
  let s: seq[float] = @[1.0, 2,3,4,5]
  result = newLit(s)

block:
  let tmp: seq[float] = test_newLit_seq_float
  doAssert tmp == @[1.0, 2,3,4,5]

macro test_newLit_seq_float32: untyped =
  let s: seq[float32] = @[1.0'f32, 2,3,4,5]
  result = newLit(s)

block:
  let tmp: seq[float32] = test_newLit_seq_float32
  doAssert tmp == @[1.0'f32, 2,3,4,5]

macro test_newLit_seq_float64: untyped =
  let s: seq[float64] = @[1.0'f64, 2,3,4,5]
  result = newLit(s)

block:
  let tmp: seq[float64] = test_newLit_seq_float64
  doAssert tmp == @[1.0'f64, 2,3,4,5]

macro test_newLit_tuple: untyped =
  let tup: tuple[a:int,b:string] = (a: 123, b: "223")
  result = newLit(tup)

doAssert test_newLit_tuple == (a: 123, b: "223")

type
  ComposedType = object
    mt: MyType
    arr: array[4,int]
    data: seq[byte]

macro test_newLit_ComposedType: untyped =
  let ct = ComposedType(mt: MyType(a: 123, b:"abc"), arr: [1,2,3,4], data: @[1.byte, 3, 7, 127])
  result = newLit(ct)

doAssert test_newLit_ComposedType == ComposedType(mt: MyType(a: 123, b:"abc"), arr: [1,2,3,4], data: @[1.byte, 3, 7, 127])

macro test_newLit_empty_seq_string: untyped =
  var strSeq = newSeq[string](0)
  result = newLit(strSeq)

block:
  # x needs to be of type seq[string]
  var x = test_newLit_empty_seq_string
  x.add("xyz")

type
  MyEnum = enum
    meA
    meB

macro test_newLit_Enum: untyped =
  result = newLit(meA)

block:
  let tmp: MyEnum = meA
  doAssert tmp == test_newLit_Enum

macro test_newLit_set: untyped =
  let myset = {MyEnum.low .. MyEnum.high}
  result = newLit(myset)

block:
  let tmp: set[MyEnum] = {MyEnum.low .. MyEnum.high}
  doAssert tmp == test_newLit_set

macro test_newLit_ref_object: untyped =
  var x = RefObject(x: 10)
  return newLit(x)

block:
  let x = test_newLit_ref_object()
  doAssert $(x[]) == "(x: 10)"

macro test_newLit_object_ref_alias: untyped =
  var x = ObjectRefAlias(x: 10)
  return newLit(x)

block:
  let x = test_newLit_object_ref_alias()
  doAssert $(x[]) == "(x: 10)"

