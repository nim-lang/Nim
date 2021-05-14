discard """
  targets: "c cpp js"
"""

import stdtest/testutils

from std/math import PI
from std/fenv import epsilon

template main =
  var res = newStringOfCap(24)
  template toStr(x): untyped =
    let x2 = x # prevents const folding
    res.setLen(0)
    res.addFloat x2
    doAssert res == $x2 # sanity check
    res

  block: # addFloat
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

      toStr(-0.0) == "-0.0"
      toStr(1000000000000000.0) == "1000000000000000.0"
      toStr(PI) == "3.141592653589793"
      toStr(1.23e-8) == "1.23e-8"
      toStr(10.23e-9) == "1.023e-8"
      toStr(-10.23e-9) == "-1.023e-8"
      toStr(5e-324) == "5e-324"
      toStr(50e22) == "5e+23"
      toStr(5e22) == "5e+22"
      toStr(-5e22) == "-5e+22"
      toStr(50e20) == "5e+21"

    block: # nan, inf + cases that differ in js RT
      whenRuntimeJs:
        assertAll:
          toStr(NaN) == "NaN"
          toStr(Inf) == "Infinity"
          toStr(1.0 / 0.0) == "Infinity"
          toStr(-1.0 / 0.0) == "-Infinity"
          toStr(50e18) == "50000000000000000000.0"
      do:
        assertAll:
          toStr(NaN) == "nan"
          toStr(Inf) == "inf"
          toStr(1.0 / 0.0) == "inf"
          toStr(-1.0 / 0.0) == "-inf"
          toStr(50e18) == "5e+19"

    block:
      let a = 123456789
      when not defined(js):
        # xxx in VM, gives: Error: VM does not support 'cast' from tyInt to tyFloat
        let b = cast[float](a)
        assertAll:
          # xxx in js RT, this shows 123456789.0, ie, the cast is interpreted as a conversion
          toStr(b) == "6.0995758e-316" # nim 1.4 would produce 6.09957581907715e-316
          b == 6.0995758e-316
          cast[int](b) == a

static: main()
main()
