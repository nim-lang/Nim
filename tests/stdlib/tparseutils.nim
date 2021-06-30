import parseutils
import sequtils

let input = "$test{}  $this is ${an{  example}}  "
let expected = @[(ikVar, "test"), (ikStr, "{}  "), (ikVar, "this"),
                  (ikStr, " is "), (ikExpr, "an{  example}"), (ikStr, "  ")]
doAssert toSeq(interpolatedFragments(input)) == expected

var value = 0
discard parseHex("0x38", value)
doAssert value == 56

var wrong = 0
discard parseHex("0x10ffff_ffff_ffff_ffff", wrong)
doAssert wrong == 0

value = -1
doAssert(parseSaturatedNatural("848", value) == 3)
doAssert value == 848

value = -1
discard parseSaturatedNatural("84899999999999999999324234243143142342135435342532453", value)
doAssert value == high(int)

value = -1
discard parseSaturatedNatural("9223372036854775808", value)
doAssert value == high(int)

value = -1
discard parseSaturatedNatural("9223372036854775807", value)
doAssert value == high(int)

value = -1
discard parseSaturatedNatural("18446744073709551616", value)
doAssert value == high(int)

value = -1
discard parseSaturatedNatural("18446744073709551615", value)
doAssert value == high(int)

value = -1
doAssert(parseSaturatedNatural("1_000_000", value) == 9)
doAssert value == 1_000_000

var i64Value: int64
discard parseBiggestInt("9223372036854775807", i64Value)
doAssert i64Value == 9223372036854775807


template parseHexCheck[T](a: string, expected: T) =
  var ret: T
  doAssert parseHex(a, ret) == a.len
  doAssert ret == expected

template parseOctCheck[T](a: string, expected: T) =
  var ret: T
  doAssert parseOct(a, ret) == a.len
  doAssert ret == expected

block:
  var num8: int8
  doAssert parseOct("0o_1464_755", num8) == 0
  doAssert num8 == 0
  doAssert parseOct("0o_1464_755", num8, 3, 3) == 3
  doAssert num8 == 102
  var num8u: uint8
  doAssert parseOct("1464755", num8u) == 0
  doAssert num8u == 0

  var num64i: int64
  doAssert parseOct("2777777777777777777777", num64i) == 0

  parseOctCheck("1777777777777777777777", -1'i64)
  parseOctCheck("0_77777777777777777777", 1152921504606846975'i64)
  parseOctCheck("0o1777777777777777777777", -1'i64)

  var num64u: uint64
  doAssert parseOct("2777777777777777777777", num64u) == 0

  parseOctCheck("1777777777777777777777", 18446744073709551615'u64)
  parseOctCheck("0_77777777777777777777", 1152921504606846975'u64)
  parseOctCheck("0o1777777777777777777777", 18446744073709551615'u64)


  var num32i: int32
  doAssert parseOct("0o47777777777", num32i) == 0

  parseOctCheck("0o37777777777", -1'i32)
  parseOctCheck("0o7777777777", 1073741823'i32)
  parseOctCheck("0o37777777777", -1'i32)

  var num32u: uint32
  doAssert parseOct("0o47777777777", num32u) == 0

  parseOctCheck("0o37777777777", 4294967295'u32)
  parseOctCheck("0o7777777777", 1073741823'u32)
  parseOctCheck("0o37777777777", 4294967295'u32)

  var num16i: int16
  doAssert parseOct("277777", num16i) == 0

  parseOctCheck("0o177777", -1'i16)
  parseOctCheck("0o7777", 4095'i16)
  parseOctCheck("0o177777", -1'i16)

  var num16u: uint16
  parseOctCheck("0o177777", 65535'u16)

  doAssert parseOct("277777", num16u) == 0

  parseOctCheck("0o7777", 4095'u16)
  parseOctCheck("0o177777", 65535'u16)


  var num8i: int8
  parseOctCheck("0o377", -1'i8)

  doAssert parseOct("477", num8i) == 0

  parseOctCheck("0o77", 63'i8)
  parseOctCheck("0o377", -1'i8)

  parseOctCheck("0o377", 255'u8)

  doAssert parseOct("477", num8u) == 0
  parseOctCheck("0o77", 63'u8)
  parseOctCheck("0o377", 255'u8)

block:
  var num8: int8
  doAssert parseBin("0b_0100_1110_0110_1001_1110_1101", num8) == 0
  doAssert num8 == 0'i8
  doAssert parseBin("0b_0100_1110_0110_1001_1110_1101", num8, 3, 9) == 9
  doAssert num8 == 0b0100_1110'i8
  var num8u: uint8
  doAssert parseBin("0b_0100_1110_0110_1001_1110_1101", num8u) == 0
  doAssert num8u == 0

block:
  var num8: int8
  doAssert parseHex("0x_4E_69_ED", num8) == 0
  doAssert num8 == 0'i8
  doAssert parseHex("0x_4E_69_ED", num8, 3, 2) == 2
  doAssert num8 == 0x4E'i8
  var num8u: uint8
  doAssert parseHex("0x_4E_69_ED", num8u) == 0
  doAssert num8u == 0'u8

  var num64i: int64
  parseHexCheck("0xFFFF_FFFF_FFFF_FFFF", -1'i64)

  doAssert parseHex("0x10FFFF_FFFF_FFFF_FFFF", num64i) == 0

  parseHexCheck("0x1FFF_FFFF_FFFF_FFFF", 2305843009213693951'i64)

  parseHexCheck("0x0000FFFF_FFFF_FFFF_FFFF", -1'i64)


  var num64u: uint64
  parseHexCheck("0xFFFF_FFFF_FFFF_FFFF", 18446744073709551615'u64)

  doAssert parseHex("0x10FFFF_FFFF_FFFF_FFFF", num64u) == 0

  parseHexCheck("0x1FFF_FFFF_FFFF_FFFF", 2305843009213693951'u64)
  parseHexCheck("0x0000FFFF_FFFF_FFFF_FFFF", 18446744073709551615'u64)

  var num32i: int32
  parseHexCheck("0xFFFFFFFF", -1'i32)

  doAssert parseHex("10FFFF_FFFF", num32i) == 0

  parseHexCheck("0x1FFF_FFFF", 536870911'i32)
  parseHexCheck("0x0000_FFFF_FFFF", -1'i32)

  var num32u: uint32
  parseHexCheck("0xFFFF_FFFF", 4294967295'u32)

  doAssert parseHex("0x10FFFF_FFFF", num32u) == 0

  parseHexCheck("0x1FFF_FFFF", 536870911'u32)

  parseHexCheck("0x0000_FFFF_FFFF", 4294967295'u32)

  var num16i: int16
  parseHexCheck("0xFFFF", -1'i16)

  doAssert parseHex("10FFFF", num16i) == 0

  parseHexCheck("0x1FFF", 8191'i16)
  parseHexCheck("0x0000_FFFF", -1'i16)

  var num16u: uint16
  parseHexCheck("0xFFFF", 65535'u16)

  doAssert parseHex("0x10FFFF", num16u) == 0

  parseHexCheck("0x1FFF", 8191'u16)
  parseHexCheck("0x0000_FFFF", 65535'u16)
