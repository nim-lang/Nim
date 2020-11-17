#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 b3liever
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.

## Fast sumation functions.


func sumKbn*[T](x: openArray[T]): T =
  ## Kahan (compensated) summation: O(1) error growth, at the expense
  ## of a considerable increase in computational expense.
  if len(x) == 0: return
  var sum = x[0]
  var c = T(0)
  for i in 1 ..< len(x):
    let xi = x[i]
    let t = sum + xi
    if abs(sum) >= abs(xi):
      c += (sum - t) + xi
    else:
      c += (xi - t) + sum
    sum = t
  result = sum + c

func sumPairwise[T](x: openArray[T], i0, n: int): T =
  if n < 128:
    result = x[i0]
    for i in i0 + 1 ..< i0 + n:
      result += x[i]
  else:
    let n2 = n div 2
    result = sumPairwise(x, i0, n2) + sumPairwise(x, i0 + n2, n - n2)

func sumPairs*[T](x: openArray[T]): T =
  ## Pairwise (cascade) summation of ``x[i0:i0+n-1]``, with O(log n) error growth
  ## (vs O(n) for a simple loop) with negligible performance cost if
  ## the base case is large enough.
  ##
  ## See, e.g.:
  ## * http://en.wikipedia.org/wiki/Pairwise_summation
  ##   Higham, Nicholas J. (1993), "The accuracy of floating point
  ##   summation", SIAM Journal on Scientific Computing 14 (4): 783–799.
  ##
  ## In fact, the root-mean-square error growth, assuming random roundoff
  ## errors, is only O(sqrt(log n)), which is nearly indistinguishable from O(1)
  ## in practice. See:
  ## * Manfred Tasche and Hansmartin Zeuner, Handbook of
  ##   Analytic-Computational Methods in Applied Mathematics (2000).
  ##
  let n = len(x)
  if n == 0: T(0) else: sumPairwise(x, 0, n)


runnableExamples:
  static:
    block:
      const data = [1, 2, 3, 4, 5, 6, 7, 8, 9]
      doAssert sumKbn(data) == 45
      doAssert sumPairs(data) == 45


when isMainModule:
  from math import pow

  var epsilon = 1.0
  while 1.0 + epsilon != 1.0:
    epsilon /= 2.0
  let data = @[1.0, epsilon, -epsilon]
  assert sumKbn(data) == 1.0
  assert sumPairs(data) != 1.0 # known to fail
  assert (1.0 + epsilon) - epsilon != 1.0

  var tc1: seq[float]
  for n in 1 .. 1000:
    tc1.add 1.0 / n.float
  assert sumKbn(tc1) == 7.485470860550345
  assert sumPairs(tc1) == 7.485470860550345

  var tc2: seq[float]
  for n in 1 .. 1000:
    tc2.add pow(-1.0, n.float) / n.float
  assert sumKbn(tc2) == -0.6926474305598203
  assert sumPairs(tc2) == -0.6926474305598204
