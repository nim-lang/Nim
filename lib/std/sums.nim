#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.

## Accurate summation functions.
runnableExamples:
  import std/math

  template `=~`(x, y: float): bool = abs(x - y) < 1e-4

  let
    n = 1_000_000
    first = 1e10
    small = 0.1
  var data = @[first]
  for _ in 1 .. n:
    data.add(small)

  let result = first + small * n.float

  assert abs(sum(data) - result) > 0.3
  assert sumKbn(data) =~ result
  assert sumKbk(data) =~ result
  assert sumPairs(data) =~ result

## See also
## ========
## * `math module <math.html>`_ for a standard `sum proc <math.html#sum,openArray[T]>`_

func sumKbn*[T: SomeFloat](x: openArray[T]): T =
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

func sumKbk*[T: SomeFloat](x: openArray[T]): T =
  ## Kahan-Babuška-Klein variant, a second-order "iterative Kahan–Babuška algorithm".
  ##
  ## See:
  ## * https://en.wikipedia.org/wiki/Kahan_summation_algorithm#Further_enhancements
  var cs = T(0)
  var ccs = T(0)
  var sum = x[0]
  for i in 1 ..< len(x):
    var c = T(0)
    var cc = T(0)
    let xi = x[i]
    var t = sum + xi
    if abs(sum) >= abs(xi):
      c = (sum - t) + xi
    else:
      c = (xi - t) + sum
    sum = t
    t = cs + c
    if abs(cs) >= abs(c):
      cc = (cs - t) + c
    else:
      cc = (c - t) + cs
    cs = t
    ccs = ccs + cc
  result = sum + cs + ccs

func sumPairwise[T](x: openArray[T], i0, n: int): T =
  if n < 128:
    result = x[i0]
    for i in i0 + 1 ..< i0 + n:
      result += x[i]
  else:
    let n2 = n div 2
    result = sumPairwise(x, i0, n2) + sumPairwise(x, i0 + n2, n - n2)

func sumPairs*[T: SomeFloat](x: openArray[T]): T =
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

func partials[T](v: openArray[T]): seq[T] {.inline.} =
  for x in v.items:
    var x = x
    var i = 0
    for y in result.items:
      var y = y
      if abs(x) < abs(y):
        let temp = x
        x = y
        y = temp
      let hi = x + y
      let lo = y - (hi - x)
      if lo != 0:
        result[i] = lo
        inc(i)
      x = hi
    setLen(result, i + 1)
    result[i] = x

func sumShewchuck*[T: SomeFloat](x: openArray[T]): T =
  ## Shewchuk's summation
  ## Full precision sum of values in iterable. Returns the value of the
  ## sum, rounded to the nearest representable floating-point number
  ## using the round-half-to-even rule
  ##
  ## See also:
  ## - https://docs.python.org/3/library/math.html#math.fsum
  ## - https://code.activestate.com/recipes/393090/
  ##
  ## Reference:
  ## Shewchuk, JR. (1996) Adaptive Precision Floating-Point Arithmetic and \
  ## Fast Robust GeometricPredicates.
  ## http://www-2.cs.cmu.edu/afs/cs/project/quake/public/papers/robust-arithmetic.ps
  let p = partials(x)
  var hi = T(0)
  var n = p.len
  if n > 0:
    dec(n)
    hi = p[n]
    var lo = T(0)
    while n > 0:
      var x = hi
      dec(n)
      var y = p[n]
      hi = x + y
      let yr = hi - x
      let lo = y - yr
      if lo != 0:
        break
      if n > 0 and ((lo < 0 and p[n - 1] < 0) or
                    (lo > 0 and p[n - 1] > 0)):
        y = lo * T(2)
        x = hi + y
        let yr = x - hi
        if y == yr:
          hi = x
  result = hi
