discard """
  matrix: "--mm:refc; --mm:orc"
"""

import std/[dec64, dec64math]
from std/math as fm import nil          # qualified-only access for cross-checks
import std/formatfloat
when defined(nimPreviewSlimSystem):
  import std/assertions

func absF(x: float): float =
  if x < 0: -x else: x

template approxEq(a, b: Dec64, eps = 1e-12'f64): bool =
  absF(a.toFloat - b.toFloat) < eps

template approxEqFloat(a: Dec64, b: float, relEps = 1e-14'f64): bool =
  let af = a.toFloat
  if b == 0.0: absF(af) < relEps
  else:        absF(af - b) / absF(b) < relEps

template main() =
  block: # native rounding (no float trip, exact decimal)
    doAssert floor(1.7'dec) == 1'dec
    doAssert floor(-1.3'dec) == -2'dec
    doAssert floor(2'dec) == 2'dec
    doAssert floor(-0.5'dec) == -1'dec
    doAssert floor(0'dec) == 0'dec

    doAssert ceil(1.3'dec) == 2'dec
    doAssert ceil(-1.7'dec) == -1'dec
    doAssert ceil(2'dec) == 2'dec
    doAssert ceil(-0.5'dec) == 0'dec

    doAssert trunc(1.7'dec) == 1'dec
    doAssert trunc(-1.7'dec) == -1'dec
    doAssert trunc(0.5'dec) == 0'dec
    doAssert trunc(-0.5'dec) == 0'dec

    doAssert round(0.5'dec) == 1'dec
    doAssert round(-0.5'dec) == -1'dec
    doAssert round(1.5'dec) == 2'dec
    doAssert round(-1.5'dec) == -2'dec
    doAssert round(0.4'dec) == 0'dec
    doAssert round(-0.4'dec) == 0'dec

    doAssert isNaN(floor(nan))
    doAssert isNaN(ceil(nan))
    doAssert isNaN(round(nan))
    doAssert isNaN(trunc(nan))

  block: # abs / sign
    doAssert abs(3'dec) == 3'dec
    doAssert abs(-3'dec) == 3'dec
    doAssert abs(0'dec) == 0'dec
    doAssert isNaN(abs(nan))

    doAssert sign(7'dec) == 1
    doAssert sign(-7'dec) == -1
    doAssert sign(0'dec) == 0
    doAssert sign(nan) == 0

  block: # integer-exponent pow (exact, native decimal)
    doAssert pow(2'dec, 0) == 1'dec
    doAssert pow(2'dec, 1) == 2'dec
    doAssert pow(2'dec, 10) == 1024'dec
    doAssert pow(1.05'dec, 2) == 1.1025'dec
    doAssert pow(1.05'dec, 4) == 1.21550625'dec      # exact at 9 digits
    doAssert pow(2'dec, -3) == 0.125'dec
    doAssert pow(10'dec, 5) == 100000'dec
    doAssert isNaN(pow(nan, 3))

  block: # toFloat round-trip
    doAssert toFloat(0'dec) == 0.0
    doAssert toFloat(1'dec) == 1.0
    doAssert toFloat(-2.5'dec) == -2.5
    doAssert toFloat(125'dec) == 125.0
    let f = toFloat(1.25'dec)
    doAssert f == 1.25
    doAssert toFloat(nan) != toFloat(nan)             # IEEE NaN

  block: # factorial
    doAssert factorial(0) == 1'dec
    doAssert factorial(1) == 1'dec
    doAssert factorial(5) == 120'dec
    doAssert factorial(10) == 3628800'dec
    doAssert factorial(15) == 1307674368000'dec
    doAssert isNaN(factorial(-1))
    doAssert isNaN(factorial(100))                    # well beyond Dec64 range

  block: # transcendental identities
    doAssert sqrt(0'dec) == 0'dec
    doAssert sqrt(1'dec) == 1'dec
    doAssert sqrt(4'dec) == 2'dec
    doAssert sqrt(0.25'dec) == 0.5'dec

    doAssert approxEqFloat(exp(0'dec), 1.0)
    doAssert approxEqFloat(ln(1'dec), 0.0, relEps = 1e-15)
    doAssert approxEqFloat(sin(0'dec), 0.0, relEps = 1e-15)
    doAssert approxEqFloat(cos(0'dec), 1.0)
    doAssert approxEqFloat(tan(0'dec), 0.0, relEps = 1e-15)

  block: # std/math agreement
    let inputs = [0.5, 1.0, 1.5, 2.0, 3.14, 7.0, 12.0]
    for f in inputs:
      let x = parse($f)
      doAssert approxEqFloat(sqrt(x), fm.sqrt(f))
      doAssert approxEqFloat(exp(x), fm.exp(f))
      doAssert approxEqFloat(ln(x), fm.ln(f))
      doAssert approxEqFloat(sin(x), fm.sin(f), relEps = 1e-13)
      doAssert approxEqFloat(cos(x), fm.cos(f), relEps = 1e-13)

  block: # inverse pairs
    for f in [0.1, 1.0, 2.71828, 10.0, 100.0]:
      let x = parse($f)
      doAssert approxEq(exp(ln(x)), x, eps = 1e-12)

    for f in [-1.0, -0.3, 0.0, 0.3, 1.0]:
      let x = parse($f)
      let r = sin(arcsin(x))
      doAssert approxEq(r, x, eps = 1e-13)

    for f in [0.25, 1.0, 4.0, 9.0, 100.0]:
      let x = parse($f)
      doAssert approxEq(pow(sqrt(x), 2'dec), x, eps = 1e-12)

  block: # pow(Dec64, Dec64) and nthRoot
    doAssert approxEqFloat(pow(2'dec, 0.5'dec), fm.pow(2.0, 0.5))
    doAssert approxEqFloat(pow(10'dec, 0.5'dec), fm.pow(10.0, 0.5))
    doAssert approxEq(nthRoot(8'dec, 3), 2'dec, eps = 1e-13)
    doAssert approxEq(nthRoot(27'dec, 3), 3'dec, eps = 1e-13)

  block: # arctan2 quadrants
    doAssert approxEqFloat(arctan2(1'dec, 1'dec), fm.arctan2(1.0, 1.0))
    doAssert approxEqFloat(arctan2(1'dec, -1'dec), fm.arctan2(1.0, -1.0))
    doAssert approxEqFloat(arctan2(-1'dec, -1'dec), fm.arctan2(-1.0, -1.0))
    doAssert approxEqFloat(arctan2(-1'dec, 1'dec), fm.arctan2(-1.0, 1.0))

  block: # NaN / domain propagation
    doAssert isNaN(sqrt(nan))
    doAssert isNaN(sqrt(-1'dec))
    doAssert isNaN(ln(0'dec))
    doAssert isNaN(ln(-1'dec))
    doAssert isNaN(arcsin(2'dec))
    doAssert isNaN(arccos(2'dec))
    doAssert isNaN(exp(nan))
    doAssert isNaN(sin(nan))

  block: # dec64FromFloat (fast) vs dec64FromFloatPrecise
    # Both must agree on simple values where the float is itself exact.
    for f in [0.0, 1.0, -1.0, 2.5, -2.5, 100.0, 0.5, 0.25]:
      doAssert dec64FromFloat(f) == dec64FromFloatPrecise(f)

    # NaN/Inf both saturate to nan.
    doAssert isNaN(dec64FromFloat(0.0/0.0))
    doAssert isNaN(dec64FromFloatPrecise(0.0/0.0))
    doAssert isNaN(dec64FromFloat(Inf))
    doAssert isNaN(dec64FromFloatPrecise(Inf))

    # The fast and precise paths may differ by at most ~1-2 ulp at the 16th
    # decimal digit. They are required to agree to within 2e-15 relative.
    for f in [0.1, 0.2, 0.3, 1.0/3.0, 2.0/7.0, 3.14159265358979]:
      let a = dec64FromFloat(f)
      let b = dec64FromFloatPrecise(f)
      let af = a.toFloat
      let bf = b.toFloat
      let denom = if bf == 0.0: 1.0 else: bf
      doAssert absF(af - bf) / absF(denom) < 2e-15

  block: # range edge: float64 saturation -> Dec64 nan
    let big = exp(50'dec)
    doAssert not isNaN(big)
    doAssert isNaN(exp(1000'dec))                     # float64 overflows -> nan
    doAssert isNaN(pow(10'dec, 500'dec))

when isMainModule:
  main()
