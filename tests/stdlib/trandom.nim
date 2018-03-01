discard """
  targets: "js c c++"
  output: '''ok'''
"""

import math, random

const
  n = 100_000
  count = 100

proc rank(arr: openarray[int]): int =
  let h = high(arr)
  for i in 0 .. h - 1:
    let f = fac(h - i)
    for j in i + 1 .. h:
      if arr[j] < arr[i]:
        result += f

proc isRandom(freqs: openarray[int]; n: int): bool =
  ## Calculates the chi-square value for N positive integers less than r
  ## Source: "Algorithms in C" - Robert Sedgewick - pp. 517
  ## NB: Sedgewick recommends: "...to be sure, the test should be tried a few times,
  ## since it could be wrong in about one out of ten times."
  let r = freqs.len
  let n_r = n/r
  # This is valid if N is greater than about 10r
  assert(n > 10 * r)
  # Calculate chi-square
  var chiSquare = 0.0
  for f in freqs:
    let t = float(f) - n_r
    chiSquare += pow(t, 2.0)
  chiSquare = chiSquare / n_r
  # The statistic should be within 2(r)^1/2 of r
  abs(chiSquare - float(r)) <= 2.0 * sqrt(float(r))

proc testRandInt =
  # Get frequency of randoms
  var freqs: array[count, int]
  for i in 1 .. n:
    freqs[rand(count-1)].inc
  doAssert isRandom(freqs, n)

proc testRandFloat =
  var freqs: array[count, int]
  for i in 1 .. n:
    freqs[int(rand(1.0) * float(count))].inc
  doAssert isRandom(freqs, n)

proc testShuffle =
  var freqs: array[120, int]
  for i in 1 .. n:
    var a = [0, 1, 2, 3, 4]
    shuffle(a)
    freqs[rank(a)].inc
  doAssert isRandom(freqs, n)

testRandInt()
testRandFloat()
testShuffle()
echo "ok"
