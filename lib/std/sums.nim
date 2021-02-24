#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 b3liever
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.

## Accurate summation functions.

runnableExamples:
  import std/math

  template `~=`(x, y: float): bool = abs(x - y) < 1e-4

  let
    n = 1_000_000
    first = 1e10
    small = 0.1
  var data = @[first]
  for _ in 1 .. n:
    data.add(small)

  let result = first + small * n.float

  doAssert abs(sum(data) - result) > 0.3
  doAssert sumKbn(data) ~= result
  doAssert sumPairs(data) ~= result

## See also
## ========
## * `math module <math.html>`_ for a standard `sum proc <math.html#sum,openArray[T]>`_

func sumKbn*[T](x: openArray[T]): T =
  ## Kahan-Babuška-Neumaier summation: O(1) error growth, at the expense
  ## of a considerable increase in computational cost.
  ##
  ## See:
  ## * https://en.wikipedia.org/wiki/Kahan_summation_algorithm#Further_enhancements
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
  ## Pairwise (cascade) summation of `x[i0:i0+n-1]`, with O(log n) error growth
  ## (vs O(n) for a simple loop) with negligible performance cost if
  ## the base case is large enough.
  ##
  ## See, e.g.:
  ## * https://en.wikipedia.org/wiki/Pairwise_summation
  ## * Higham, Nicholas J. (1993), "The accuracy of floating point
  ##   summation", SIAM Journal on Scientific Computing 14 (4): 783–799.
  ##
  ## In fact, the root-mean-square error growth, assuming random roundoff
  ## errors, is only O(sqrt(log n)), which is nearly indistinguishable from O(1)
  ## in practice. See:
  ## * Manfred Tasche and Hansmartin Zeuner, Handbook of
  ##   Analytic-Computational Methods in Applied Mathematics (2000).
  let n = len(x)
  if n == 0: T(0) else: sumPairwise(x, 0, n)
