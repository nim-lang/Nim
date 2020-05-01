discard """
  cmd:      "nim c -r --styleCheck:hint --panics:on $options $file"
  matrix:   "-d:danger; -d:release"
  targets:  "c cpp"
  nimout:   ""
  action:   "run"
  exitcode: 0
  timeout:  60.0
"""

import std/varints


block:
  var dest: array[50, byte]
  var got: uint64

  for test in [0xFFFF_FFFF_FFFFF_FFFFu64, 77u64, 0u64, 10_000_000u64, uint64(high(int64)),
              uint64(high(int32)), uint64(high(int32)), uint64(high(int64))]:
    let wrLen = writeVu64(dest, test)
    let rdLen = readVu64(dest, got)
    doAssert wrLen == rdLen
    doAssert got == test

  for test in 0u64..300u64:
    let wrLen = writeVu64(dest, test)
    let rdLen = readVu64(dest, got)
    doAssert wrLen == rdLen
    doAssert got == test

  # check this also works for floats:
  for test in [0.0, 0.1, 2.0, +Inf, NegInf]:
    let t = cast[uint64](test)
    let wrLenB = writeVu64(dest, t)
    let rdLenB = readVu64(dest, got)
    doAssert wrLenB == rdLenB
    doAssert cast[float64](got) == test

block:
  var hugeIntArray: array[50, byte]
  var readedInt: uint64
  doAssert writeVu64(hugeIntArray, 0.uint64) == readVu64(hugeIntArray, readedInt)
  doAssert readedInt == 0.uint64
  doAssert writeVu64(hugeIntArray, uint64.high) == readVu64(hugeIntArray, readedInt)
  doAssert readedInt == uint64.high
  doAssert writeVu64(hugeIntArray, uint64(int64.high)) == readVu64(hugeIntArray, readedInt)
  doAssert readedInt == uint64(int64.high)
  doAssert writeVu64(hugeIntArray, uint64(int32.high)) == readVu64(hugeIntArray, readedInt)
  doAssert readedInt == uint64(int32.high)
  doAssert writeVu64(hugeIntArray, uint64(int16.high)) == readVu64(hugeIntArray, readedInt)
  doAssert readedInt == uint64(int16.high)
  doAssert writeVu64(hugeIntArray, uint64(int8.high)) == readVu64(hugeIntArray, readedInt)
  doAssert readedInt == uint64(int8.high)
  doAssert writeVu64(hugeIntArray, cast[uint64](0.0)) == readVu64(hugeIntArray, readedInt)
  doAssert readedInt == cast[uint64](0.0)
  doAssert writeVu64(hugeIntArray, cast[uint64](-0.0)) == readVu64(hugeIntArray, readedInt)
  doAssert readedInt == cast[uint64](-0.0)
  doAssert writeVu64(hugeIntArray, cast[uint64](0.1)) == readVu64(hugeIntArray, readedInt)
  doAssert readedInt == cast[uint64](0.1)
  doAssert writeVu64(hugeIntArray, cast[uint64](0.9555555555555555555555501)) == readVu64(hugeIntArray, readedInt)
  doAssert readedInt == cast[uint64](0.9555555555555555555555501)
  doAssert writeVu64(hugeIntArray, cast[uint64](+Inf)) == readVu64(hugeIntArray, readedInt)
  doAssert readedInt == cast[uint64](+Inf)
  doAssert writeVu64(hugeIntArray, cast[uint64](NegInf)) == readVu64(hugeIntArray, readedInt)
  doAssert readedInt == cast[uint64](NegInf)
  doAssert writeVu64(hugeIntArray, cast[uint64](Nan)) == readVu64(hugeIntArray, readedInt)
  doAssert readedInt == cast[uint64](Nan)
  doAssert writeVu64(hugeIntArray, cast[uint64](3.1415926535897932384626433)) == readVu64(hugeIntArray, readedInt)
  doAssert readedInt == cast[uint64](3.1415926535897932384626433)
  doAssert writeVu64(hugeIntArray, cast[uint64](2.71828182845904523536028747)) == readVu64(hugeIntArray, readedInt)
  doAssert readedInt == cast[uint64](2.71828182845904523536028747)

block:
  doAssert encodeZigzag(decodeZigzag(0.uint64)) == 0.uint64
  doAssert encodeZigzag(decodeZigzag(uint64(uint32.high))) == uint64(uint32.high)
  doAssert encodeZigzag(decodeZigzag(uint64(int32.high))) == uint64(int32.high)
  doAssert encodeZigzag(decodeZigzag(uint64(int16.high))) == uint64(int16.high)
  doAssert encodeZigzag(decodeZigzag(uint64(int8.high))) == uint64(int8.high)
  doAssert encodeZigzag(decodeZigzag(cast[uint64](0.0))) == cast[uint64](0.0)
  doAssert encodeZigzag(decodeZigzag(cast[uint64](0.1))) == cast[uint64](0.1)
  doAssert encodeZigzag(decodeZigzag(cast[uint64](0.9555555555555555555555501))) == cast[uint64](0.9555555555555555555555501)
  doAssert encodeZigzag(decodeZigzag(cast[uint64](+Inf))) == cast[uint64](+Inf)
  doAssert encodeZigzag(decodeZigzag(cast[uint64](3.1415926535897932384626433))) == cast[uint64](3.1415926535897932384626433)
  doAssert encodeZigzag(decodeZigzag(cast[uint64](2.71828182845904523536028747))) == cast[uint64](2.71828182845904523536028747)
