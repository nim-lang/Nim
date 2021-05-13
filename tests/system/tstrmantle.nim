discard """
  targets: "c cpp js"
"""

import stdtest/testutils

template main =
  var res = newStringOfCap(24)
  template toStr(x): untyped =
    res.setLen(0)
    res.addInt x
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
      0.toStr == "0"
      (-0).toStr == "0"
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

static: main()
main()
