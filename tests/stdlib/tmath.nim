discard """
  action: run
  output: '''[Suite] random int

[Suite] random float

[Suite] cumsum

[Suite] random sample

[Suite] ^

'''
"""

import math, random, os
import unittest
import sets, tables

suite "random int":
  test "there might be some randomness":
    var set = initHashSet[int](128)

    for i in 1..1000:
      incl(set, random(high(int)))
    check len(set) == 1000
  test "single number bounds work":

    var rand: int
    for i in 1..1000:
      rand = random(1000)
      check rand < 1000
      check rand > -1
  test "slice bounds work":

    var rand: int
    for i in 1..1000:
      rand = random(100..1000)
      check rand < 1000
      check rand >= 100
  test " again gives new numbers":

    var rand1 = random(1000000)
    os.sleep(200)

    var rand2 = random(1000000)
    check rand1 != rand2


suite "random float":
  test "there might be some randomness":
    var set = initSet[float](128)

    for i in 1..100:
      incl(set, random(1.0))
    check len(set) == 100
  test "single number bounds work":

    var rand: float
    for i in 1..1000:
      rand = random(1000.0)
      check rand < 1000.0
      check rand > -1.0
  test "slice bounds work":

    var rand: float
    for i in 1..1000:
      rand = random(100.0..1000.0)
      check rand < 1000.0
      check rand >= 100.0
  test " again gives new numbers":

    var rand1:float = random(1000000.0)
    os.sleep(200)

    var rand2:float = random(1000000.0)
    check rand1 != rand2

suite "cumsum":
  test "cumsum int seq return":
    let counts = [ 1, 2, 3, 4 ]
    check counts.cumsummed == [ 1, 3, 6, 10 ]

  test "cumsum float seq return":
    let counts = [ 1.0, 2.0, 3.0, 4.0 ]
    check counts.cumsummed == [ 1.0, 3.0, 6.0, 10.0 ]

  test "cumsum int in-place":
    var counts = [ 1, 2, 3, 4 ]
    counts.cumsum
    check counts == [ 1, 3, 6, 10 ]

  test "cumsum float in-place":
    var counts = [ 1.0, 2.0, 3.0, 4.0 ]
    counts.cumsum
    check counts == [ 1.0, 3.0, 6.0, 10.0 ]

suite "random sample":
  test "non-uniform array sample unnormalized int CDF":
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

  test "non-uniform array sample normalized float CDF":
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

suite "^":
  test "compiles for valid types":
    check: compiles(5 ^ 2)
    check: compiles(5.5 ^ 2)
    check: compiles(5.5 ^ 2.int8)
    check: compiles(5.5 ^ 2.uint)
    check: compiles(5.5 ^ 2.uint8)
    check: not compiles(5.5 ^ 2.2)