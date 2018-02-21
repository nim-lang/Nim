discard """
  targets: "js c c++"
  output: '''ok'''
"""

import math, random

const
  n = 1000_000
  max = 100

proc isRandom(freqs: openarray[int]; n: int): bool =
  ## Calculates the chi-square value for N positive integers less than r
  ## Source: "Algorithms in C" - Robert Sedgewick - pp. 517
  # According to Sedgewick: "This is valid if N is greater than about 10r"
  let r = freqs.len
  let n_r = n/r
  if n <= 10 * r:
    return false
  # Calculate chi-square - this approach is in Sedgewick
  var chiSquare = 0.0
  for v in freqs:
    let f = float(v) - n_r
    chiSquare += pow(f, 2.0)
  chiSquare = chiSquare / n_r
  # According to Sedgewick: "The statistic should be within 2(r)^1/2 of r
  if abs(chiSquare - float(r)) <= 2.0 * sqrt(float(r)):
    true
  else:
    echo chiSquare
    false

template testGen(count, index) =
  # Get frequency of randoms
  var freqs: array[count, int]
  for i in 1 .. n:
    freqs[index] += 1
  doAssert isRandom(freqs, n)

proc main =
  testGen(max+1):
    rand(max)
  testGen(max+1):
    int(rand(1.0) * float(max+1))
  echo "ok"

main()
