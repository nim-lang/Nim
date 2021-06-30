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
  doAssert parseOct("1777777777777777777777", num64i) == 22
  doAssert num64i == -1'i64

  doAssert parseOct("2777777777777777777777", num64i) == 0

  doAssert parseOct("0_77777777777777777777", num64i) == 22
  doAssert num64i == 1152921504606846975'i64

  doAssert parseOct("0o1777777777777777777777", num64i) == 24
  doAssert num64i == -1'i64


  var num64u: uint64
  doAssert parseOct("1777777777777777777777", num64u) == 22
  doAssert num64u == 18446744073709551615'u64

  doAssert parseOct("2777777777777777777777", num64u) == 0

  doAssert parseOct("0_77777777777777777777", num64u) == 22
  doAssert num64u == 1152921504606846975'u64

  doAssert parseOct("0o1777777777777777777777", num64u) == 24
  doAssert num64u == 18446744073709551615'u64


  var num32i: int32
  doAssert parseOct("0o37777777777", num32i) == 13
  doAssert num32i == -1'i32

  doAssert parseOct("0o47777777777", num32i) == 0

  doAssert parseOct("0o7777777777", num32i) == 12
  doAssert num32i == 1073741823'i32

  doAssert parseOct("0o37777777777", num32i) == 13
  doAssert num32i == -1'i32

  var num32u: uint32
  doAssert parseOct("0o37777777777", num32u) == 13
  doAssert num32u == 4294967295'u32

  doAssert parseOct("0o47777777777", num32u) == 0

  doAssert parseOct("0o7777777777", num32u) == 12
  doAssert num32u == 1073741823'u32

  doAssert parseOct("0o37777777777", num32u) == 13
  doAssert num32u == 4294967295'u32


  var num16i: int16
  doAssert parseOct("0o177777", num16i) == 8
  doAssert num16i == -1'i16

  doAssert parseOct("277777", num16i) == 0

  doAssert parseOct("0o7777", num16i) == 6
  doAssert num16i == 4095'i16

  doAssert parseOct("0o177777", num16i) == 8
  doAssert num16i == -1'i16


  var num16u: uint16
  doAssert parseOct("0o177777", num16u) == 8
  doAssert num16u == 65535'u16

  doAssert parseOct("277777", num16u) == 0

  doAssert parseOct("0o7777", num16u) == 6
  doAssert num16u == 4095'u16

  doAssert parseOct("0o177777", num16u) == 8
  doAssert num16u == 65535'u16


  var num8i: int8
  doAssert parseOct("0o377", num8i) == 5
  doAssert num8i == -1'i8

  doAssert parseOct("477", num8i) == 0

  doAssert parseOct("0o77", num8i) == 4
  doAssert num8i == 63'i8

  doAssert parseOct("0o377", num8i) == 5
  doAssert num8i == -1'i8

  doAssert parseOct("0o377", num8u) == 5
  doAssert num8u == 255'u8

  doAssert parseOct("477", num8u) == 0

  doAssert parseOct("0o77", num8u) == 4
  doAssert num8u == 63'u8

  doAssert parseOct("0o377", num8u) == 5
  doAssert num8u == 255'u8

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
  doAssert parseHex("0xFFFF_FFFF_FFFF_FFFF", num64i) == 21
  doAssert num64i == -1'i64

  doAssert parseHex("0x10FFFF_FFFF_FFFF_FFFF", num64i) == 0

  doAssert parseHex("0x1FFF_FFFF_FFFF_FFFF", num64i) == 21
  doAssert num64i == 2305843009213693951'i64

  doAssert parseHex("0x0000FFFF_FFFF_FFFF_FFFF", num64i) == 25
  doAssert num64i == -1'i64


  var num64u: uint64
  doAssert parseHex("0xFFFF_FFFF_FFFF_FFFF", num64u) == 21
  doAssert num64u == 18446744073709551615'u64

  doAssert parseHex("0x10FFFF_FFFF_FFFF_FFFF", num64u) == 0

  doAssert parseHex("0x1FFF_FFFF_FFFF_FFFF", num64u) == 21
  doAssert num64u == 2305843009213693951'u64

  doAssert parseHex("0x0000FFFF_FFFF_FFFF_FFFF", num64u) == 25
  doAssert num64u == 18446744073709551615'u64


  var num32i: int32
  doAssert parseHex("0xFFFFFFFF", num32i) == 10
  doAssert num32i == -1'i32

  doAssert parseHex("10FFFF_FFFF", num32i) == 0

  doAssert parseHex("0x1FFF_FFFF", num32i) == 11
  doAssert num32i == 536870911'i32

  doAssert parseHex("0x0000_FFFF_FFFF", num32i) == 16
  doAssert num32i == -1'i32


  var num32u: uint32
  doAssert parseHex("0xFFFF_FFFF", num32u) == 11
  doAssert num32u == 4294967295'u32

  doAssert parseHex("0x10FFFF_FFFF", num32u) == 0

  doAssert parseHex("0x1FFF_FFFF", num32u) == 11
  doAssert num32u == 536870911'u32

  doAssert parseHex("0x0000_FFFF_FFFF", num32u) == 16
  doAssert num32u == 4294967295'u32


  var num16i: int16
  doAssert parseHex("0xFFFF", num16i) == 6
  doAssert num16i == -1'i16

  doAssert parseHex("10FFFF", num16i) == 0

  doAssert parseHex("0x1FFF", num16i) == 6
  doAssert num16i == 8191'i16

  doAssert parseHex("0x0000_FFFF", num16i) == 11
  doAssert num16i == -1'i16


  var num16u: uint16
  doAssert parseHex("0xFFFF", num16u) == 6
  doAssert num16u == 65535'u16

  doAssert parseHex("0x10FFFF", num16u) == 0

  doAssert parseHex("0x1FFF", num16u) == 6
  doAssert num16u == 8191'u16

  doAssert parseHex("0x0000_FFFF", num16u) == 11
  doAssert num16u == 65535'u16
