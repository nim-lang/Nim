import macros
from stdtest/testutils import disableVM
type
  Dollar = distinct int
  XCoord = distinct int32
  Digit = range[-9..0]

# those are necessary for comparisons below.
proc `==`(x, y: Dollar): bool {.borrow.}
proc `==`(x, y: XCoord): bool {.borrow.}

proc dummy[T](x: T): T = x

template roundTrip(a, T) =
  let a2 = a # sideeffect safe
  let b = cast[T](a2)
  let c = cast[type(a2)](b)
  doAssert c == a2

proc test() =
  let U8 = 0b1011_0010'u8
  let I8 = 0b1011_0010'i8
  let C8 = 0b1011_0010'u8.char
  let C8_1 = 0b1011_0011'u8.char
  let U16 = 0b10100111_00101000'u16
  let I16 = 0b10100111_00101000'i16
  let U32 = 0b11010101_10011100_11011010_01010000'u32
  let I32 = 0b11010101_10011100_11011010_01010000'i32
  let U64A = 0b11000100_00111111_01111100_10001010_10011001_01001000_01111010_00010001'u64
  let I64A = 0b11000100_00111111_01111100_10001010_10011001_01001000_01111010_00010001'i64
  let U64B = 0b00110010_11011101_10001111_00101000_00000000_00000000_00000000_00000000'u64
  let I64B = 0b00110010_11011101_10001111_00101000_00000000_00000000_00000000_00000000'i64
  when sizeof(int) == 8:
    let UX = U64A.uint
    let IX = I64A.int
  elif sizeof(int) == 4:
    let UX = U32.uint
    let IX = I32.int
  elif sizeof(int) == 2:
    let UX = U16.uint
    let IX = I16.int
  else:
    let UX = U8.uint
    let IX = I8.int

  doAssert(cast[char](I8) == C8)
  doAssert(cast[uint8](I8) == U8)
  doAssert(cast[uint16](I16) == U16)
  doAssert(cast[uint32](I32) == U32)
  doAssert(cast[uint64](I64A) == U64A)
  doAssert(cast[uint64](I64B) == U64B)
  doAssert(cast[int8](U8) == I8)
  doAssert(cast[int16](U16) == I16)
  doAssert(cast[int32](U32) == I32)
  doAssert(cast[int64](U64A) == I64A)
  doAssert(cast[int64](U64B) == I64B)
  doAssert(cast[uint](IX) == UX)
  doAssert(cast[int](UX) == IX)

  doAssert(cast[char](I8 + 1) == C8_1)
  doAssert(cast[uint8](I8 + 1) == U8 + 1)
  doAssert(cast[uint16](I16 + 1) == U16 + 1)
  doAssert(cast[uint32](I32 + 1) == U32 + 1)
  doAssert(cast[uint64](I64A + 1) == U64A + 1)
  doAssert(cast[uint64](I64B + 1) == U64B + 1)
  doAssert(cast[int8](U8 + 1) == I8 + 1)
  doAssert(cast[int16](U16 + 1) == I16 + 1)
  doAssert(cast[int32](U32 + 1) == I32 + 1)
  doAssert(cast[int64](U64A + 1) == I64A + 1)
  doAssert(cast[int64](U64B + 1) == I64B + 1)
  doAssert(cast[uint](IX + 1) == UX + 1)
  doAssert(cast[int](UX + 1) == IX + 1)

  doAssert(cast[char](I8.dummy) == C8.dummy)
  doAssert(cast[uint8](I8.dummy) == U8.dummy)
  doAssert(cast[uint16](I16.dummy) == U16.dummy)
  doAssert(cast[uint32](I32.dummy) == U32.dummy)
  doAssert(cast[uint64](I64A.dummy) == U64A.dummy)
  doAssert(cast[uint64](I64B.dummy) == U64B.dummy)
  doAssert(cast[int8](U8.dummy) == I8.dummy)
  doAssert(cast[int16](U16.dummy) == I16.dummy)
  doAssert(cast[int32](U32.dummy) == I32.dummy)
  doAssert(cast[int64](U64A.dummy) == I64A.dummy)
  doAssert(cast[int64](U64B.dummy) == I64B.dummy)
  doAssert(cast[uint](IX.dummy) == UX.dummy)
  doAssert(cast[int](UX.dummy) == IX.dummy)


  doAssert(cast[int64](if false: U64B else: 0'u64) == (if false: I64B else: 0'i64))

  block:
    let raw = 3
    let money = Dollar(raw) # this must be a variable, is otherwise constant folded.
    doAssert(cast[int](money) == raw)
    doAssert(cast[Dollar](raw) == money)
  block:
    let raw = 150'i32
    let position = XCoord(raw) # this must be a variable, is otherwise constant folded.
    doAssert(cast[int32](position) == raw)
    doAssert(cast[XCoord](raw) == position)
  block:
    let raw = -2
    let digit = Digit(raw)
    doAssert(cast[int](digit) == raw)
    doAssert(cast[Digit](raw) == digit)

  block:
    roundTrip(I64A, float)
    roundTrip(I8, uint16)
    roundTrip(I8, uint32)
    roundTrip(I8, uint64)
    doAssert cast[uint16](I8) == 65458'u16
    doAssert cast[uint32](I8) == 4294967218'u32
    doAssert cast[uint64](I8) == 18446744073709551538'u64
    doAssert cast[uint32](I64A) == 2571663889'u32
    doAssert cast[uint16](I64A) == 31249
    doAssert cast[char](I64A).ord == 17
    doAssert compiles(cast[float32](I64A))

  disableVM: # xxx Error: VM does not support 'cast' from tyInt64 to tyFloat32
    doAssert cast[uint32](cast[float32](I64A)) == 2571663889'u32

const prerecordedResults = [
  # cast to char
  "\0", "\255",
  "\0", "\255",
  "\0", "\255",
  "\0", "\255",
  "\0", "\255",
  "\128", "\127",
  "\0", "\255",
  "\0", "\255",
  "\0", "\255",
  # cast to uint8
  "0", "255",
  "0", "255",
  "0", "255",
  "0", "255",
  "0", "255",
  "128", "127",
  "0", "255",
  "0", "255",
  "0", "255",
  # cast to uint16
  "0", "255",
  "0", "255",
  "0", "65535",
  "0", "65535",
  "0", "65535",
  "65408", "127",
  "32768", "32767",
  "0", "65535",
  "0", "65535",
  # cast to uint32
  "0", "255",
  "0", "255",
  "0", "65535",
  "0", "4294967295",
  "0", "4294967295",
  "4294967168", "127",
  "4294934528", "32767",
  "2147483648", "2147483647",
  "0", "4294967295",
  # cast to uint64
  "0", "255",
  "0", "255",
  "0", "65535",
  "0", "4294967295",
  "0", "18446744073709551615",
  "18446744073709551488", "127",
  "18446744073709518848", "32767",
  "18446744071562067968", "2147483647",
  "9223372036854775808", "9223372036854775807",
  # cast to int8
  "0", "-1",
  "0", "-1",
  "0", "-1",
  "0", "-1",
  "0", "-1",
  "-128", "127",
  "0", "-1",
  "0", "-1",
  "0", "-1",
  # cast to int16
  "0", "255",
  "0", "255",
  "0", "-1",
  "0", "-1",
  "0", "-1",
  "-128", "127",
  "-32768", "32767",
  "0", "-1",
  "0", "-1",
  # cast to int32
  "0", "255",
  "0", "255",
  "0", "65535",
  "0", "-1",
  "0", "-1",
  "-128", "127",
  "-32768", "32767",
  "-2147483648", "2147483647",
  "0", "-1",
  # cast to int64
  "0", "255",
  "0", "255",
  "0", "65535",
  "0", "4294967295",
  "0", "-1",
  "-128", "127",
  "-32768", "32767",
  "-2147483648", "2147483647",
  "-9223372036854775808", "9223372036854775807",
]

proc free_integer_casting() =
  # cast from every integer type to every type and ensure same
  # behavior in vm and execution time.
  macro bar(arg: untyped) =
    result = newStmtList()
    var i = 0
    for it1 in arg:
      let typA = it1[0]
      for it2 in arg:
        let lowB = it2[1]
        let highB = it2[2]
        let castExpr1 = nnkCast.newTree(typA, lowB)
        let castExpr2 = nnkCast.newTree(typA, highB)
        let lit1 = newLit(prerecordedResults[i*2])
        let lit2 = newLit(prerecordedResults[i*2+1])
        result.add quote do:
          doAssert($(`castExpr1`) == `lit1`)
          doAssert($(`castExpr2`) == `lit2`)
        i += 1

  bar([
    (char, '\0', '\255'),
    (uint8, 0'u8, 0xff'u8),
    (uint16, 0'u16, 0xffff'u16),
    (uint32, 0'u32, 0xffffffff'u32),
    (uint64, 0'u64, 0xffffffffffffffff'u64),
    (int8,  0x80'i8, 0x7f'i8),
    (int16, 0x8000'i16, 0x7fff'i16),
    (int32, 0x80000000'i32, 0x7fffffff'i32),
    (int64, 0x8000000000000000'i64, 0x7fffffffffffffff'i64)
  ])

proc test_float_cast =

  const
    exp_bias = 1023'i64
    exp_shift = 52
    exp_mask = 0x7ff'i64 shl exp_shift
    mantissa_mask = 0xfffffffffffff'i64

  let f = 8.0
  let fx = cast[int64](f)
  let exponent = ((fx and exp_mask) shr exp_shift) - exp_bias
  let mantissa = fx and mantissa_mask
  doAssert(exponent == 3, $exponent)
  doAssert(mantissa == 0, $mantissa)

  # construct 2^N float, where N is integer
  let x = -2'i64
  let xx = (x + exp_bias) shl exp_shift
  let xf = cast[float](xx)
  doAssert(xf == 0.25, $xf)

proc test_float32_cast =

  const
    exp_bias = 127'i32
    exp_shift = 23
    exp_mask = 0x7f800000'i32
    mantissa_mask = 0x007ffff'i32

  let f = -0.5'f32
  let fx = cast[int32](f)
  let exponent = ((fx and exp_mask) shr exp_shift) - exp_bias
  let mantissa = fx and mantissa_mask
  doAssert(exponent == -1, $exponent)
  doAssert(mantissa == 0, $mantissa)

  # construct 2^N float32 where N is integer
  let x = 4'i32
  let xx = (x + exp_bias) shl exp_shift
  let xf = cast[float32](xx)
  doAssert(xf == 16.0'f32, $xf)

proc test_float32_castB() =
  let a: float32 = -123.125
  let b = cast[int32](a)
  let c = cast[uint32](a)
  doAssert b == -1024049152
  doAssert cast[uint64](b) == 18446744072685502464'u64
  doAssert c == 3270918144'u32
  # ensure the unused bits in the internal representation don't have
  # any surprising content.
  doAssert cast[uint64](c) == 3270918144'u64

template main() =
  test()
  test_float_cast()
  test_float32_cast()
  free_integer_casting()
  test_float32_castB()

static: main()
main()
