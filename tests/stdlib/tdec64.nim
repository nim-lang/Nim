discard """
  matrix: "--mm:refc; --mm:orc"
"""

import std/[dec64, hashes]
when defined(nimPreviewSlimSystem):
  import std/assertions

template main() =
  block: # pack / unpack
    let x = dec64(125, -2)            # 1.25
    doAssert x.coefficient == 125
    doAssert x.exponent == -2
    doAssert not isNaN(x)
    doAssert not isZero(x)

  block: # pack / unpack negative
    let x = dec64(-7, 3)              # -7000
    doAssert x.coefficient == -7
    doAssert x.exponent == 3
    doAssert $x == "-7000"

  block: # NaN bit pattern
    doAssert isNaN(nan)
    doAssert nan.exponent == -128

  block: # 255 zero representations
    for e in -10..10:
      doAssert dec64(0, e) == zero
      doAssert isZero(dec64(0, e))
      doAssert hash(dec64(0, e)) == hash(zero)

  block: # equality / ordering
    doAssert dec64(1) == dec64(1)
    doAssert dec64(10, 0) == dec64(1, 1)        # 10 == 10
    doAssert dec64(100, -2) == dec64(1, 0)      # 1.00 == 1
    doAssert dec64(1, 0) < dec64(2, 0)
    doAssert dec64(-1, 0) < dec64(0, 0)
    doAssert dec64(0, 0) < dec64(1, -50)        # 0 < tiny positive
    doAssert dec64(999, -3) < dec64(1, 0)       # 0.999 < 1
    doAssert dec64(1, 0) <= dec64(1, 0)
    doAssert cmp(dec64(1, 0), dec64(2, 0)) == -1
    doAssert cmp(dec64(2, 0), dec64(1, 0)) == 1
    doAssert cmp(dec64(1, 0), dec64(1, 0)) == 0

  block: # nan semantics
    doAssert nan == nan
    doAssert not (nan < dec64(0))
    doAssert not (dec64(0) < nan)
    doAssert isNaN(nan + dec64(1))
    doAssert isNaN(dec64(1) - nan)
    doAssert isNaN(nan * nan)
    doAssert isNaN(nan / dec64(1))
    doAssert isNaN(dec64(1) / dec64(0))
    doAssert isNaN(-nan)

  block: # addition
    # equal-exponent fast path
    doAssert dec64(2) + dec64(3) == dec64(5)
    doAssert dec64(-2) + dec64(2) == zero
    # different exponents
    doAssert dec64(125, -2) + dec64(2, 0) == dec64(325, -2)
    doAssert $(dec64(125, -2) + dec64(2)) == "3.25"
    # carry beyond 56 bits
    let big = dec64(coeffMax, 0) + dec64(1)
    doAssert big.exponent >= 1                  # was scaled down
    doAssert not isNaN(big)

  block: # subtraction
    doAssert dec64(5) - dec64(3) == dec64(2)
    doAssert dec64(125, -2) - dec64(25, -2) == dec64(1)
    doAssert dec64(0) - dec64(7) == dec64(-7)

  block: # multiplication
    doAssert dec64(2) * dec64(3) == dec64(6)
    doAssert dec64(125, -2) * dec64(4) == dec64(5)         # 1.25 * 4 = 5
    doAssert dec64(-3) * dec64(7) == dec64(-21)
    doAssert dec64(0) * dec64(coeffMax) == zero
    # 1000 * 1000 — exact, no normalization concerns
    doAssert dec64(1000) * dec64(1000) == dec64(1_000_000)
    # large operands that force renormalization through the 128-bit path
    doAssert dec64(2_000_000_000) * dec64(3_000_000_000) == dec64(6, 18)

  block: # division
    doAssert dec64(6) / dec64(2) == dec64(3)
    let third = dec64(1) / dec64(3)
    doAssert third.coefficient == 3_333_333_333_333_333'i64
    doAssert third.exponent == -16
    doAssert $third == "0.3333333333333333"
    doAssert isNaN(dec64(1) / dec64(0))
    doAssert dec64(0) / dec64(5) == zero

  block: # string round-trip
    let cases = [
      "0", "1", "-1", "100", "-100",
      "1.25", "-1.25", "0.001", "-0.001",
      "3.14159", "1000000000",
    ]
    for s in cases:
      let v = parse(s)
      doAssert not isNaN(v), "failed to parse " & s
      doAssert $v == s, "round-trip failed: " & s & " -> " & $v
    doAssert $nan == "nan"
    doAssert parse("nan") == nan
    doAssert isNaN(parse("garbage"))
    doAssert isNaN(parse("1e"))           # incomplete exponent
    doAssert isNaN(parse(""))             # empty
    doAssert isNaN(parse("1.2.3"))        # double point

  block: # exponent in literal
    doAssert parse("1e3") == dec64(1, 3)
    doAssert parse("-2.5e2") == dec64(-25, 1)              # -250
    doAssert parse("1.5E-2") == dec64(15, -3)              # 0.015

  block: # isInteger
    doAssert isInteger(dec64(5))
    doAssert isInteger(dec64(50, -1))                     # 5.0 is integer
    doAssert not isInteger(dec64(125, -2))                # 1.25 is not
    doAssert not isInteger(nan)

  block: # compound assignment
    var x = dec64(10)
    x += dec64(5);  doAssert x == dec64(15)
    x -= dec64(3);  doAssert x == dec64(12)
    x *= dec64(2);  doAssert x == dec64(24)
    x /= dec64(4);  doAssert x == dec64(6)

  block: # min-coefficient negation
    # `-coeffMin` does not fit in 56 bits, so negation renormalizes and may
    # round by 1 ulp. We require sane sign / magnitude, not bit-exact inversion.
    let minC = dec64(coeffMin, 0)
    let negated = -minC
    doAssert not isNaN(negated)
    doAssert minC < zero
    doAssert negated > zero
    doAssert (minC + negated) < dec64(10)         # near-zero residual
    doAssert (minC + negated) > dec64(-10)

  block: # 'dec literal
    doAssert 1'dec == dec64(1)
    doAssert 100'dec == dec64(100)
    doAssert -5'dec == dec64(-5)                     # parsed as -(5'dec)
    doAssert 1.25'dec == dec64(125, -2)
    doAssert 0.07'dec == dec64(7, -2)
    doAssert 7e-2'dec == dec64(7, -2)

  block: # mixed (Dec64, int)
    let price = 19.99'dec
    doAssert price * 2 == 39.98'dec
    doAssert 100 - price == 80.01'dec
    doAssert price + 1 == 20.99'dec
    doAssert price / 2 == 9.995'dec
    doAssert 1 + 2'dec * 3 == 7'dec                    # operator precedence preserved
    doAssert price < 20
    doAssert 19 < price
    doAssert price <= 19.99'dec
    doAssert price > 0
    doAssert price >= 19
    doAssert dec64(5) == 5
    doAssert 5 == dec64(5)

  block: # float construction
    doAssert dec64(1.25) == dec64(125, -2)
    doAssert dec64(0.0) == zero
    doAssert isNaN(dec64(0.0 / 0.0))             # IEEE NaN -> Dec64 nan

  block: # hash
    doAssert hash(dec64(1, 0)) == hash(dec64(10, -1))      # equal values
    doAssert hash(dec64(1, 0)) == hash(dec64(100, -2))
    doAssert hash(zero) == hash(dec64(0, 50))

when isMainModule:
  main()
