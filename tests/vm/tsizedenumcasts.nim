discard
  """
  targets: "c cpp"
"""

import std/assertions

type
  Mask8 {.size: 1.} = enum
    flag8 = 1

  Mask16 {.size: 2.} = enum
    flag16 = 1

  Mask32 {.size: 4.} = enum
    flag32 = 1

  Mask64 {.size: 8.} = enum
    flag64 = 1 shl 27

  MaskAlias = Mask64
  DistinctMask = distinct Mask64
  MaskFields = object
    first, second: Mask64

const
  all8 = cast[Mask8](uint8.high)
  all16 = cast[Mask16](uint16.high)
  all32 = cast[Mask32](uint32.high)
  all64 = cast[Mask64](uint64.high)
  upperBit = cast[MaskAlias](1'u64 shl 40)

proc checkMasks() =
  doAssert cast[uint8](all8) == uint8.high
  doAssert cast[uint16](all16) == uint16.high
  doAssert cast[uint32](all32) == uint32.high
  doAssert cast[uint64](all64) == uint64.high
  doAssert cast[uint64](upperBit) == 1'u64 shl 40
  let raw = 0xFEDC_BA98_7654_3210'u64
  let mask = cast[Mask64](raw)
  doAssert cast[uint64](mask) == raw
  let distinctMask = cast[DistinctMask](raw)
  doAssert cast[uint64](distinctMask) == raw
  let fields = MaskFields(first: mask, second: upperBit)
  doAssert cast[uint64](fields.first) == raw
  doAssert cast[uint64](fields.second) == 1'u64 shl 40
  let masks = [mask, upperBit, all64]
  doAssert cast[uint64](masks[0]) == raw
  doAssert cast[uint64](masks[1]) == 1'u64 shl 40
  doAssert cast[uint64](masks[2]) == uint64.high

static:
  checkMasks()
checkMasks()
