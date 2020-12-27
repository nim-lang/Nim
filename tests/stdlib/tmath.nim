discard """
  action: run
  matrix:"; -d:nimTmathCase2 -d:danger --passc:-ffast-math"
"""

# xxx: fix bugs for js then add: targets:"c js"

import math, random, os
import unittest
import sets, tables

block: # random int
  block: # there might be some randomness
    var set = initHashSet[int](128)

    for i in 1..1000:
      incl(set, rand(high(int)))
    check len(set) == 1000

  block: # single number bounds work
    var rand: int
    for i in 1..1000:
      rand = rand(1000)
      check rand < 1000
      check rand > -1

  block: # slice bounds work
    var rand: int
    for i in 1..1000:
      rand = rand(100..1000)
      when defined(js): # xxx bug: otherwise fails
        check rand <= 1000
      else:
        check rand < 1000
      check rand >= 100

  block: # again gives new numbers
    var rand1 = rand(1000000)
    when not defined(js):
      os.sleep(200)

    var rand2 = rand(1000000)
    check rand1 != rand2


block: # random float
  block: # there might be some randomness
    var set = initHashSet[float](128)

    for i in 1..100:
      incl(set, rand(1.0))
    check len(set) == 100

  block: # single number bounds work
    var rand: float
    for i in 1..1000:
      rand = rand(1000.0)
      check rand < 1000.0
      check rand > -1.0

  block: # slice bounds work
    var rand: float
    for i in 1..1000:
      rand = rand(100.0..1000.0)
      check rand < 1000.0
      check rand >= 100.0

  block: # again gives new numbers

    var rand1:float = rand(1000000.0)
    when not defined(js):
      os.sleep(200)

    var rand2:float = rand(1000000.0)
    check rand1 != rand2

block: # cumsum
  block: # cumsum int seq return
    let counts = [ 1, 2, 3, 4 ]
    check counts.cumsummed == [ 1, 3, 6, 10 ]

  block: # cumsum float seq return
    let counts = [ 1.0, 2.0, 3.0, 4.0 ]
    check counts.cumsummed == [ 1.0, 3.0, 6.0, 10.0 ]

  block: # cumsum int in-place
    var counts = [ 1, 2, 3, 4 ]
    counts.cumsum
    check counts == [ 1, 3, 6, 10 ]

  block: # cumsum float in-place
    var counts = [ 1.0, 2.0, 3.0, 4.0 ]
    counts.cumsum
    check counts == [ 1.0, 3.0, 6.0, 10.0 ]

block: # random sample
  block: # "non-uniform array sample unnormalized int CDF
    let values = [ 10, 20, 30, 40, 50 ] # values
    let counts = [ 4, 3, 2, 1, 0 ]      # weights aka unnormalized probabilities
    var histo = initCountTable[int]()
    let cdf = counts.cumsummed          # unnormalized CDF
    for i in 0 ..< 5000:
      histo.inc(sample(values, cdf))
    check histo.len == 4                # number of non-zero in `counts`
    # Any one bin is a binomial random var for n samples, each with prob p of
    # adding a count to k; E[k]=p*n, Var k=p*(1-p)*n, approximately Normal for
    # big n.  So, P(abs(k - p*n)/sqrt(p*(1-p)*n))>3.0) =~ 0.0027, while
    # P(wholeTestFails) =~ 1 - P(binPasses)^4 =~ 1 - (1-0.0027)^4 =~ 0.01.
    for i, c in counts:
      if c == 0:
        check values[i] notin histo
        continue
      let p = float(c) / float(cdf[^1])
      let n = 5000.0
      let expected = p * n
      let stdDev = sqrt(n * p * (1.0 - p))
      check abs(float(histo[values[i]]) - expected) <= 3.0 * stdDev

  block: # non-uniform array sample normalized float CDF
    let values = [ 10, 20, 30, 40, 50 ]     # values
    let counts = [ 0.4, 0.3, 0.2, 0.1, 0 ]  # probabilities
    var histo = initCountTable[int]()
    let cdf = counts.cumsummed              # normalized CDF
    for i in 0 ..< 5000:
      histo.inc(sample(values, cdf))
    check histo.len == 4                    # number of non-zero in ``counts``
    for i, c in counts:
      if c == 0:
        check values[i] notin histo
        continue
      let p = float(c) / float(cdf[^1])
      let n = 5000.0
      let expected = p * n
      let stdDev = sqrt(n * p * (1.0 - p))
      # NOTE: like unnormalized int CDF test, P(wholeTestFails) =~ 0.01.
      check abs(float(histo[values[i]]) - expected) <= 3.0 * stdDev

block: # ^
  block: # compiles for valid types
    check: compiles(5 ^ 2)
    check: compiles(5.5 ^ 2)
    check: compiles(5.5 ^ 2.int8)
    check: compiles(5.5 ^ 2.uint)
    check: compiles(5.5 ^ 2.uint8)
    check: not compiles(5.5 ^ 2.2)

block:
  when not defined(js):
    # Check for no side effect annotation
    proc mySqrt(num: float): float {.noSideEffect.} =
      # xxx unused
      return sqrt(num)

    # check gamma function
    doAssert(gamma(5.0) == 24.0) # 4!
    doAssert(lgamma(1.0) == 0.0) # ln(1.0) == 0.0
    doAssert(erf(6.0) > erf(5.0))
    doAssert(erfc(6.0) < erfc(5.0))


    # Function for approximate comparison of floats
    proc `==~`(x, y: float): bool = (abs(x-y) < 1e-9)

    block: # prod
      doAssert prod([1, 2, 3, 4]) == 24
      doAssert prod([1.5, 3.4]) == 5.1
      let x: seq[float] = @[]
      doAssert prod(x) == 1.0

    block: # round() tests
      # Round to 0 decimal places
      doAssert round(54.652) ==~ 55.0
      doAssert round(54.352) ==~ 54.0
      doAssert round(-54.652) ==~ -55.0
      doAssert round(-54.352) ==~ -54.0
      doAssert round(0.0) ==~ 0.0

    block: # splitDecimal() tests
      doAssert splitDecimal(54.674).intpart ==~ 54.0
      doAssert splitDecimal(54.674).floatpart ==~ 0.674
      doAssert splitDecimal(-693.4356).intpart ==~ -693.0
      doAssert splitDecimal(-693.4356).floatpart ==~ -0.4356
      doAssert splitDecimal(0.0).intpart ==~ 0.0
      doAssert splitDecimal(0.0).floatpart ==~ 0.0

    block: # trunc tests for vcc
      doAssert(trunc(-1.1) == -1)
      doAssert(trunc(1.1) == 1)
      doAssert(trunc(-0.1) == -0)
      doAssert(trunc(0.1) == 0)

      #special case
      doAssert(classify(trunc(1e1000000)) == fcInf)
      doAssert(classify(trunc(-1e1000000)) == fcNegInf)
      when not defined(nimTmathCase2):
        doAssert(classify(trunc(0.0/0.0)) == fcNan)
      doAssert(classify(trunc(0.0)) == fcZero)

      #trick the compiler to produce signed zero
      let
        f_neg_one = -1.0
        f_zero = 0.0
        f_nan = f_zero / f_zero

      doAssert(classify(trunc(f_neg_one*f_zero)) == fcNegZero)

      doAssert(trunc(-1.1'f32) == -1)
      doAssert(trunc(1.1'f32) == 1)
      doAssert(trunc(-0.1'f32) == -0)
      doAssert(trunc(0.1'f32) == 0)
      doAssert(classify(trunc(1e1000000'f32)) == fcInf)
      doAssert(classify(trunc(-1e1000000'f32)) == fcNegInf)
      when not defined(nimTmathCase2):
        doAssert(classify(trunc(f_nan.float32)) == fcNan)
      doAssert(classify(trunc(0.0'f32)) == fcZero)

    block: # sgn() tests
      doAssert sgn(1'i8) == 1
      doAssert sgn(1'i16) == 1
      doAssert sgn(1'i32) == 1
      doAssert sgn(1'i64) == 1
      doAssert sgn(1'u8) == 1
      doAssert sgn(1'u16) == 1
      doAssert sgn(1'u32) == 1
      doAssert sgn(1'u64) == 1
      doAssert sgn(-12342.8844'f32) == -1
      doAssert sgn(123.9834'f64) == 1
      doAssert sgn(0'i32) == 0
      doAssert sgn(0'f32) == 0
      doAssert sgn(NegInf) == -1
      doAssert sgn(Inf) == 1
      doAssert sgn(NaN) == 0

    block: # fac() tests
      try:
        discard fac(-1)
      except AssertionDefect:
        discard

      doAssert fac(0) == 1
      doAssert fac(1) == 1
      doAssert fac(2) == 2
      doAssert fac(3) == 6
      doAssert fac(4) == 24

    block: # floorMod/floorDiv
      doAssert floorDiv(8, 3) == 2
      doAssert floorMod(8, 3) == 2

      doAssert floorDiv(8, -3) == -3
      doAssert floorMod(8, -3) == -1

      doAssert floorDiv(-8, 3) == -3
      doAssert floorMod(-8, 3) == 1

      doAssert floorDiv(-8, -3) == 2
      doAssert floorMod(-8, -3) == -2

      doAssert floorMod(8.0, -3.0) ==~ -1.0
      doAssert floorMod(-8.5, 3.0) ==~ 0.5

    block: # euclDiv/euclMod
      doAssert euclDiv(8, 3) == 2
      doAssert euclMod(8, 3) == 2

      doAssert euclDiv(8, -3) == -2
      doAssert euclMod(8, -3) == 2

      doAssert euclDiv(-8, 3) == -3
      doAssert euclMod(-8, 3) == 1

      doAssert euclDiv(-8, -3) == 3
      doAssert euclMod(-8, -3) == 1

      doAssert euclMod(8.0, -3.0) ==~ 2.0
      doAssert euclMod(-8.5, 3.0) ==~ 0.5

      doAssert euclDiv(9, 3) == 3
      doAssert euclMod(9, 3) == 0

      doAssert euclDiv(9, -3) == -3
      doAssert euclMod(9, -3) == 0

      doAssert euclDiv(-9, 3) == -3
      doAssert euclMod(-9, 3) == 0

      doAssert euclDiv(-9, -3) == 3
      doAssert euclMod(-9, -3) == 0

    block: # log
      doAssert log(4.0, 3.0) ==~ ln(4.0) / ln(3.0)
      doAssert log2(8.0'f64) == 3.0'f64
      doAssert log2(4.0'f64) == 2.0'f64
      doAssert log2(2.0'f64) == 1.0'f64
      doAssert log2(1.0'f64) == 0.0'f64
      doAssert classify(log2(0.0'f64)) == fcNegInf

      doAssert log2(8.0'f32) == 3.0'f32
      doAssert log2(4.0'f32) == 2.0'f32
      doAssert log2(2.0'f32) == 1.0'f32
      doAssert log2(1.0'f32) == 0.0'f32
      doAssert classify(log2(0.0'f32)) == fcNegInf

template main =
  # xxx wrap all under `main` so it also gets tested in vm.
  block: # isNaN
    doAssert NaN.isNaN
    doAssert not Inf.isNaN
    doAssert isNaN(Inf - Inf)

main()
static: main()
