discard """
  targets: "c cpp"
"""

import std/[parseutils, sequtils, sugar, formatfloat]
import std/assertions

proc test() =
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

  block:
    var f: float
    let res = collect:
      for x in ["9.123456789012345+","11.123456789012345+","9.123456789012345-","8.123456789012345+","9.12345678901234-","9.123456789012345"]:
        (parseFloat(x, f, 0), $f)
    doAssert res == @[(17, "9.123456789012344"), (18, "11.123456789012344"),
                      (17, "9.123456789012344"), (17, "8.123456789012344"),
                      (16, "9.12345678901234"), (17, "9.123456789012344")]

  block:
    template ass(x) = doAssert(x) # Avoid hint[LineTooLong]
    var sz: int
    # Good, complete parses
    ass parseSize("1  b", sz)    == 4; ass sz == 1
    ass parseSize("1  B", sz)    == 4; ass sz == 1
    ass parseSize("1k", sz)      == 2; ass sz == 1000
    ass parseSize("1 kib", sz)   == 5; ass sz == 1024
    ass parseSize("1 ki", sz)    == 4; ass sz == 1024
    ass parseSize("1mi", sz)     == 3; ass sz == 1048576
    ass parseSize("1 mi", sz)    == 4; ass sz == 1048576
    ass parseSize("1 mib", sz)   == 5; ass sz == 1048576
    ass parseSize("1 Mib", sz)   == 5; ass sz == 1048576
    ass parseSize("1 MiB", sz)   == 5; ass sz == 1048576
    ass parseSize("1.23GiB", sz) == 7; ass sz == 1320702444 # 1320702443.52
    ass parseSize("0.001k", sz)  == 6; ass sz == 1
    ass parseSize("0.0004k", sz) == 7; ass sz == 0
    ass parseSize("0.0006k", sz) == 7; ass sz == 1
    # Incomplete parses
    ass parseSize("1  ", sz)     == 1; ass sz == 1  # Trailing white IGNORED
    ass parseSize("1  B ", sz)   == 4; ass sz == 1  # Trailing white IGNORED
    ass parseSize("1  B/s", sz)  == 4; ass sz == 1  # Trailing junk IGNORED
    ass parseSize("1 kX", sz)    == 3; ass sz == 1000
    ass parseSize("1 kiX", sz)   == 4; ass sz == 1024
    ass parseSize("1j", sz)      == 1; ass sz == 1  # Unknown prefix
    ass parseSize("1 jib", sz)   == 2; ass sz == 1  # ..also IGNORED
    ass parseSize("1  ji", sz)   == 3; ass sz == 1
    # Bad parses; `sz` should stay last good|incomplete val
    ass parseSize("-1b", sz)     == 0; ass sz == 1  # Negative numbers
    ass parseSize("abc", sz)     == 0; ass sz == 1  # Non-numeric
    ass parseSize(" 12", sz)     == 0; ass sz == 1  # Leading white
    # Value Edge cases
    ass parseSize("9223372036854775807", sz) == 19; ass sz == int.high.float.int

test()
static: test()
