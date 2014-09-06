import math, strutils

proc c_sprintf(buf, fmt: cstring) {.importc:"sprintf", header: "<stdio.h>", varargs.}

proc floatToStr(f: float64): string =
  var buffer: array[128, char]
  c_sprintf(buffer, "%.16e", f)
  result = ""
  for ch in buffer:
    if ch == '\0':
      return
    add(result, ch)

let testFloats = [
  "0", "-1", "1", "1.", ".3", "3.3", "-.3", "-99.99",
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

for num in testFloats:
  assert num.parseFloat.floatToStr.parseFloat == num.parseFloat

assert "0".parseFloat == 0.0
assert "-.1".parseFloat == -0.1
assert "2.5e1".parseFloat == 25.0
assert "1e10".parseFloat == 10_000_000_000.0
assert "0.000_005".parseFloat == 5.000_000e-6
assert "1.234_567e+2".parseFloat == 123.4567
assert "1e1_00".parseFloat == "1e100".parseFloat
assert "3.1415926535897932384626433".parseFloat ==
       3.1415926535897932384626433
assert "2.71828182845904523536028747".parseFloat ==
       2.71828182845904523536028747
assert 0.00097656250000000021684043449710088680149056017398834228515625 ==
     "0.00097656250000000021684043449710088680149056017398834228515625".parseFloat
