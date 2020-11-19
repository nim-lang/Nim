#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 b3liever
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.

## Fast sumation functions.


func sumKbn*[T](x: openArray[T]): T =
  ## Kahan-Babuška-Neumaier summation: O(1) error growth, at the expense
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

func fastTwoSum*[T: SomeFloat](a, b: T): (T, T) =
  ## Deker's algorithm
  ## pre-condition: |a| >= |b|
  ## you must swap a and b if pre-condition is not satisfied
  ## s + r = a + b exactly (s is result[0] and r is result[1])
  ## s is the nearest FP number of a + B
  assert(abs(a) >= abs(b))
  result[0] = a + b
  result[1] = b - (result[0] - a)

func twoSum*[T](a, b: T): (T, T) =
  ## Møller-Knuth's algorithm.
  ## Improve Deker's algorithm, no branch needed
  ## More operations, but still cheap.
  result[0] = a + b
  let z = result[0] - a
  result[1] = (a - (result[0] - z)) + (b - z)

func sum2*[T: SomeFloat](v: openArray[T]): T =
  ## sum an array v using twoSum function
  if len(v) == 0:
    return 0.0

  var s = v[0]
  var e: float
  for i in 1..<v.len-1:
    let sum = twoSum(s, v[i])
    s = sum[0]
    e += sum[1]
  return s + e

func sumShewchuck_add[T: SomeFloat](v: openArray[T]): seq[T] =
  ## Original PR: https://github.com/nim-lang/Nim/pull/9284
  ## Return partials result.
  ## Result must be summed
  for x in v:
    var x = x
    var i = 0
    for y in result:
      let sum = twoSum(x, y)
      let hi = sum[0]
      let lo = sum[1]
      if lo != 0.0:
        result[i] = lo
        i.inc
      x = hi
    setLen(result, i + 1)
    result[i] = x

func sumShewchuck_total[T: SomeFloat](partials: openArray[T]): T =
  var hi = 0.0
  if len(partials) > 0:
    var n = len(partials)
    dec(n)
    hi = partials[n]
    var lo = 0.0
    while n > 0:
      var x = hi
      dec(n)
      var y = partials[n]
      let sum = twoSum(x, y)
      hi = sum[0]
      lo = sum[1]
      if lo != 0.0:
        break
      if (n > 0 and
          (
            (lo < 0.0 and partials[n - 1] < 0.0) or
            (lo > 0.0 and partials[n - 1] > 0.0)
          )
        ):
        y = lo * 2.0
        x = hi + y
        var yr = x - hi
        if y == yr:
          hi = x
  result = hi

func sumShewchuck*[T: SomeFloat](x: openArray[T]): T =
  ## Full precision sum of values in iterable. Returns the value of the
  ## sum, rounded to the nearest representable floating-point number
  ## using the round-half-to-even rule
  ##
  ## https://docs.python.org/3/library/math.html#math.fsum
  ## https://code.activestate.com/recipes/393090/
  ## www-2.cs.cmu.edu/afs/cs/project/quake/public/papers/robust-arithmetic.ps
  sumShewchuck_total(sumShewchuck_add(x))

func fsum*[T: SomeFloat](x: openArray[T]): T =
  ## Alias of shewchuckSum function as python fsum
  sumShewchuck(x)

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
