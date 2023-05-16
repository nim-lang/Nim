discard """
  output: "passed all tests."
"""

import strutils

proc c_sprintf(buf, fmt: cstring) {.importc:"sprintf", header: "<stdio.h>", varargs.}

proc floatToStr(f: float64): string =
  var buffer: array[128, char]
  c_sprintf(cast[cstring](addr buffer), "%.16e", f)
  result = ""
  for ch in buffer:
    if ch == '\0':
      return
    add(result, ch)


let testFloats = [
  "0", "-0", "0.", "0.0", "-0.", "-0.0", "-1", "1", "1.", ".3", "3.3", "-.3", "-99.99",
  "1.1e10", "-2e100", "1.234e-10", "1.234e+10",
  "-inf", "inf", "+inf",
  "3.14159265358979323846264338327950288",
  "1.57079632679489661923132169163975144",
  "0.785398163397448309615660845819875721",
  "1.41421356237309504880168872420969808",
  "0.707106781186547524400844362104849039",
  "2.71828182845904523536028747135266250",
  "0.00097656250000000021684043449710088680149056017398834228515625"
]

when not defined(windows):
  # Windows' sprintf produces niceties like -1.#INF...
  for num in testFloats:
    doAssert num.parseFloat.floatToStr.parseFloat == num.parseFloat

doAssert "0".parseFloat == 0.0
doAssert "-.1".parseFloat == -0.1
doAssert "2.5e1".parseFloat == 25.0
doAssert "1e10".parseFloat == 10_000_000_000.0
doAssert "0.000_005".parseFloat == 5.000_000e-6
doAssert "1.234_567e+2".parseFloat == 123.4567
doAssert "1e1_00".parseFloat == "1e100".parseFloat
doAssert "3.1415926535897932384626433".parseFloat ==
       3.1415926535897932384626433
doAssert "2.71828182845904523536028747".parseFloat ==
       2.71828182845904523536028747
doAssert 0.00097656250000000021684043449710088680149056017398834228515625 ==
     "0.00097656250000000021684043449710088680149056017398834228515625".parseFloat
doAssert 0.00998333 == ".00998333".parseFloat
doAssert 0.00128333 == ".00128333".parseFloat
doAssert 999999999999999.0 == "999999999999999.0".parseFloat
doAssert 9999999999999999.0 == "9999999999999999.0".parseFloat
doAssert 0.999999999999999 == ".999999999999999".parseFloat
doAssert 0.9999999999999999 == ".9999999999999999".parseFloat

# bug #18400
var s = [-13.888888'f32]
doAssert $s[0] == "-13.888888"
var x = 1.23456789012345'f32
doAssert $x == "1.2345679"

# bug #21847
doAssert parseFloat"0e+42" == 0.0
doAssert parseFloat"0e+42949672969" == 0.0
doAssert parseFloat"0e+42949672970" == 0.0
doAssert parseFloat"0e+42949623223346323563272970" == 0.0

echo("passed all tests.")
