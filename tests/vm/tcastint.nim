discard """
  file: "tcastint.nim"
  output: "OK"
"""

type
  Dollar = distinct int
  XCoord = distinct int32
  Digit = range[-9..0]

# those are necessary for comparisons below.
proc `==`(x, y: Dollar): bool {.borrow.}
proc `==`(x, y: XCoord): bool {.borrow.}

proc dummy[T](x: T): T = x

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

  when defined nimvm:
    doAssert(not compiles(cast[float](I64A)))
    doAssert(not compiles(cast[float32](I64A)))

    doAssert(not compiles(cast[char](I64A)))
    doAssert(not compiles(cast[uint16](I64A)))
    doAssert(not compiles(cast[uint32](I64A)))

    doAssert(not compiles(cast[uint16](I8)))
    doAssert(not compiles(cast[uint32](I8)))
    doAssert(not compiles(cast[uint64](I8)))

test()
static:
  test()

echo "OK"
