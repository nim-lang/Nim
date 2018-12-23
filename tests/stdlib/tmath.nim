discard """
  action: run
  output: '''[Suite] random int

[Suite] random float

[Suite] random sample

[Suite] ^

'''
"""

import math, random, os
import unittest
import sets, tables

suite "random int":
  test "there might be some randomness":
    var set = initSet[int](128)
    randomize()
    for i in 1..1000:
      incl(set, random(high(int)))
    check len(set) == 1000
  test "single number bounds work":
    randomize()
    var rand: int
    for i in 1..1000:
      rand = random(1000)
      check rand < 1000
      check rand > -1
  test "slice bounds work":
    randomize()
    var rand: int
    for i in 1..1000:
      rand = random(100..1000)
      check rand < 1000
      check rand >= 100
  test "randomize() again gives new numbers":
    randomize()
    var rand1 = random(1000000)
    os.sleep(200)
    randomize()
    var rand2 = random(1000000)
    check rand1 != rand2


suite "random float":
  test "there might be some randomness":
    var set = initSet[float](128)
    randomize()
    for i in 1..100:
      incl(set, random(1.0))
    check len(set) == 100
  test "single number bounds work":
    randomize()
    var rand: float
    for i in 1..1000:
      rand = random(1000.0)
      check rand < 1000.0
      check rand > -1.0
  test "slice bounds work":
    randomize()
    var rand: float
    for i in 1..1000:
      rand = random(100.0..1000.0)
      check rand < 1000.0
      check rand >= 100.0
  test "randomize() again gives new numbers":
    randomize()
    var rand1:float = random(1000000.0)
    os.sleep(200)
    randomize()
    var rand2:float = random(1000000.0)
    check rand1 != rand2

suite "random sample":
  test "non-uniform array sample":
    let values = [ 10, 20, 30, 40, 50 ] # values
    let weight = [ 4, 3, 2, 1, 0 ]      # weights aka unnormalized probabilities
    let weightSum = 10.0                # sum of weights
    var histo = initCountTable[int]()
    for v in sample(values, weight, 5000):
      histo.inc(v)
    check histo.len == 4                # number of non-zero in `weight`
    # Any one bin is a binomial random var for n samples, each with prob p of
    # adding a count to k; E[k]=p*n, Var k=p*(1-p)*n, approximately Normal for
    # big n.  So, P(abs(k - p*n)/sqrt(p*(1-p)*n))>3.0) =~ 0.0027, while
    # P(wholeTestFails) =~ 1 - P(binPasses)^4 =~ 1 - (1-0.0027)^4 =~ 0.01.
    for i, w in weight:
      if w == 0:
        check values[i] notin histo
        continue
      let p = float(w) / float(weightSum)
      let n = 5000.0
      let expected = p * n
      let stdDev = sqrt(n * p * (1.0 - p))
      check abs(float(histo[values[i]]) - expected) <= 3.0 * stdDev


suite "^":
  test "compiles for valid types":
    check: compiles(5 ^ 2)
    check: compiles(5.5 ^ 2)
    check: compiles(5.5 ^ 2.int8)
    check: compiles(5.5 ^ 2.uint)
    check: compiles(5.5 ^ 2.uint8)
    check: not compiles(5.5 ^ 2.2)