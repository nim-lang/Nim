import parseutils
import sequtils

let input = "$test{}  $this is ${an{  example}}  "
let expected = @[(ikVar, "test"), (ikStr, "{}  "), (ikVar, "this"),
                  (ikStr, " is "), (ikExpr, "an{  example}"), (ikStr, "  ")]
doAssert toSeq(interpolatedFragments(input)) == expected

var value = 0
discard parseHex("0x38", value)
doAssert value == 56

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
