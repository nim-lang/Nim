discard """
  targets: "c cpp js"
"""

#[
BUG: D20210512T152059:here
testament/testament.nim r tests/system/tstrmantle.nim
runs c cpp js tests, not honoring a spec that has `targets: "cpp js"`
workaround: use: --targets:'cpp js'
e.g.:
XDG_CONFIG_HOME= nim r -b:cpp --lib:lib testament/testament.nim --nim:$nimb --targets:'cpp js' r $nim_prs_D/tests/system/tstrmantle.nim
]#

import stdtest/testutils
from std/math import PI
template main =
  var res = newStringOfCap(24)
  template toStr(x): untyped =
    res.setLen(0)
    when x is SomeFloat: res.addFloat x
    elif  x is SomeInteger: res.addInt x
    else: static: doAssert false
    doAssert res == $x # sanity check
    res

  block: # addInt
    for i in 0 .. 9:
      res.addInt int64(i)

    doAssert res == "0123456789"
    res.setLen(0)
    for i in -9 .. 0:
      res.addInt int64(i)
    doAssert res == "-9-8-7-6-5-4-3-2-10"

    assertAll:
      high(int8).toStr == "127"
      low(int8).toStr == "-128"
      high(int16).toStr == "32767"
      low(int16).toStr == "-32768"
      high(int32).toStr == "2147483647"
      low(int32).toStr == "-2147483648"

    when not defined(js):
      assertAll:
        high(int64).toStr == "9223372036854775807"
        low(int64).toStr == "-9223372036854775808"

  block: # addFloat # PRTEMP MOVE tstrfloats
    var s = "prefix"
    s.addFloat(0.1)
    assertAll:
      s == "prefix0.1"
      0.0.toStr == "0.0"
      1.0.toStr == "1.0"
      -1.0.toStr == "-1.0"
      0.3.toStr == "0.3"

      0.1 + 0.2 != 0.3
      0.1 + 0.2 == 0.30000000000000004
      toStr(0.1 + 0.2) == "0.30000000000000004" # maybe const-folding here
      let a = 0.1
      toStr(a + 0.2) == "0.30000000000000004" # no const-folding here

      toStr(NaN) == "nan"
      toStr(Inf) == "inf"
      toStr(1.0 / 0.0) == "inf"
      toStr(-1.0 / 0.0) == "-inf"
      toStr(-0.0) == "-0.0"
      toStr(1000000000000000.0) == "1000000000000000.0"
      toStr(PI) == "3.141592653589793"
      toStr(1.23e-8) == "1.23e-8"
      toStr(10.23e-9) == "1.023e-8"
      toStr(-10.23e-9) == "-1.023e-8"
      toStr(5e-324) == "5e-324"
      toStr(50e18) == "5e+19"
      toStr(51e18) == "5.1e+19"
      toStr(-51e18) == "-5.1e+19"

    block:
      let a = 123456789
      let b = cast[float](a)
      assertAll:
        toStr(b) == "6.0995758e-316" # nim 1.4 would produce 6.09957581907715e-316
        b == 6.0995758e-316
        cast[int](b) == a

static: main()
main()
