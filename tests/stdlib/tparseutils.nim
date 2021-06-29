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
