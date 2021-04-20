#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Statistical analysis framework for performing
## basic statistical analysis of data.
## The data is analysed in a single pass, when it
## is pushed to a `RunningStat` or `RunningRegress` object.
##
## `RunningStat` calculates for a single data set
## - n (data count)
## - min (smallest value)
## - max (largest value)
## - sum
## - mean
## - variance
## - varianceS (sample variance)
## - standardDeviation
## - standardDeviationS (sample standard deviation)
## - skewness (the third statistical moment)
## - kurtosis (the fourth statistical moment)
##
## `RunningRegress` calculates for two sets of data
## - n (data count)
## - slope
## - intercept
## - correlation
##
## Procs are provided to calculate statistics on `openArray`s.
##
## However, if more than a single statistical calculation is required, it is more
## efficient to push the data once to a `RunningStat` object and then
## call the numerous statistical procs for the `RunningStat` object:

runnableExamples:
  from std/math import almostEqual

  template `~=`(a, b: float): bool = almostEqual(a, b)

  var statistics: RunningStat ## Must be var
  statistics.push(@[1.0, 2.0, 1.0, 4.0, 1.0, 4.0, 1.0, 2.0])
  doAssert statistics.n == 8
  doAssert statistics.mean() ~= 2.0
  doAssert statistics.variance() ~= 1.5
  doAssert statistics.varianceS() ~= 1.714285714285715
  doAssert statistics.skewness() ~= 0.8164965809277261
  doAssert statistics.skewnessS() ~= 1.018350154434631
  doAssert statistics.kurtosis() ~= -1.0
  doAssert statistics.kurtosisS() ~= -0.7000000000000008

  block:
    var
      a4 = [6, 3, 9, 1]
      a5 = [4, 6, 3, 9, 1]
      a: array[len(a4), int]
      ax: array[len(a5), int]

    func myCmp(x, y: int): int =
      if x == y: 0 elif x < y: -1 else: 1

    a = a4
    doAssert median(a, myCmp) == 4.5
    a = a4
    doAssert median(a, mdlow, myCmp) == 3
    a = a4
    doAssert median(a, mdhigh, myCmp) == 6
    doAssert median[int](a5) == 4

from std/math import FloatClass, sqrt, pow, round

{.push debugger: off.} # the user does not want to trace a part
                       # of the standard library!
{.push checks: off, line_dir: off, stack_trace: off.}

type
  RunningStat* = object           ## An accumulator for statistical data.
    n*: int                       ## amount of pushed data
    min*, max*, sum*: float       ## self-explaining
    mom1, mom2, mom3, mom4: float ## statistical moments, mom1 is mean

  RunningRegress* = object ## An accumulator for regression calculations.
    n*: int                ## amount of pushed data
    x_stats*: RunningStat  ## stats for the first set of data
    y_stats*: RunningStat  ## stats for the second set of data
    s_xy: float            ## accumulated data for combined xy

# ----------- RunningStat --------------------------

proc clear*(s: var RunningStat) =
  ## Resets `s`.
  s.n = 0
  s.min = toBiggestFloat(int.high)
  s.max = 0.0
  s.sum = 0.0
  s.mom1 = 0.0
  s.mom2 = 0.0
  s.mom3 = 0.0
  s.mom4 = 0.0

proc push*(s: var RunningStat, x: float) =
  ## Pushes a value `x` for processing.
  if s.n == 0: s.min = x
  inc(s.n)
  # See Knuth TAOCP vol 2, 3rd edition, page 232
  if s.min > x: s.min = x
  if s.max < x: s.max = x
  s.sum += x
  let n = toFloat(s.n)
  let delta = x - s.mom1
  let delta_n = delta / toFloat(s.n)
  let delta_n2 = delta_n * delta_n
  let term1 = delta * delta_n * toFloat(s.n - 1)
  s.mom4 += term1 * delta_n2 * (n*n - 3*n + 3) +
              6*delta_n2*s.mom2 - 4*delta_n*s.mom3
  s.mom3 += term1 * delta_n * (n - 2) - 3*delta_n*s.mom2
  s.mom2 += term1
  s.mom1 += delta_n

proc push*(s: var RunningStat, x: int) =
  ## Pushes a value `x` for processing.
  ##
  ## `x` is simply converted to `float`
  ## and the other push operation is called.
  s.push(toFloat(x))

proc push*(s: var RunningStat, x: openArray[float|int]) =
  ## Pushes all values of `x` for processing.
  ##
  ## Int values of `x` are simply converted to `float` and
  ## the other push operation is called.
  for val in x:
    s.push(val)

proc mean*(s: RunningStat): float =
  ## Computes the current mean of `s`.
  result = s.mom1

proc variance*(s: RunningStat): float =
  ## Computes the current population variance of `s`.
  result = s.mom2 / toFloat(s.n)

proc varianceS*(s: RunningStat): float =
  ## Computes the current sample variance of `s`.
  if s.n > 1: result = s.mom2 / toFloat(s.n - 1)

proc standardDeviation*(s: RunningStat): float =
  ## Computes the current population standard deviation of `s`.
  result = sqrt(variance(s))

proc standardDeviationS*(s: RunningStat): float =
  ## Computes the current sample standard deviation of `s`.
  result = sqrt(varianceS(s))

proc skewness*(s: RunningStat): float =
  ## Computes the current population skewness of `s`.
  result = sqrt(toFloat(s.n)) * s.mom3 / pow(s.mom2, 1.5)

proc skewnessS*(s: RunningStat): float =
  ## Computes the current sample skewness of `s`.
  let s2 = skewness(s)
  result = sqrt(toFloat(s.n*(s.n-1)))*s2 / toFloat(s.n-2)

proc kurtosis*(s: RunningStat): float =
  ## Computes the current population kurtosis of `s`.
  result = toFloat(s.n) * s.mom4 / (s.mom2 * s.mom2) - 3.0

proc kurtosisS*(s: RunningStat): float =
  ## Computes the current sample kurtosis of `s`.
  result = toFloat(s.n-1) / toFloat((s.n-2)*(s.n-3)) *
              (toFloat(s.n+1)*kurtosis(s) + 6)

proc `+`*(a, b: RunningStat): RunningStat =
  ## Combines two `RunningStat`s.
  ##
  ## Useful when performing parallel analysis of data series
  ## and needing to re-combine parallel result sets.
  result.clear()
  result.n = a.n + b.n

  let delta = b.mom1 - a.mom1
  let delta2 = delta*delta
  let delta3 = delta*delta2
  let delta4 = delta2*delta2
  let n = toFloat(result.n)

  result.mom1 = (a.n.float*a.mom1 + b.n.float*b.mom1) / n
  result.mom2 = a.mom2 + b.mom2 + delta2 * a.n.float * b.n.float / n
  result.mom3 = a.mom3 + b.mom3 +
                delta3 * a.n.float * b.n.float * (a.n.float - b.n.float)/(n*n);
  result.mom3 += 3.0*delta * (a.n.float*b.mom2 - b.n.float*a.mom2) / n
  result.mom4 = a.mom4 + b.mom4 +
            delta4*a.n.float*b.n.float * toFloat(a.n*a.n - a.n*b.n + b.n*b.n) /
                (n*n*n)
  result.mom4 += 6.0*delta2 * (a.n.float*a.n.float*b.mom2 + b.n.float*b.n.float*a.mom2) /
                (n*n) +
                4.0*delta*(a.n.float*b.mom3 - b.n.float*a.mom3) / n
  result.max = max(a.max, b.max)
  result.min = min(a.min, b.min)

proc `+=`*(a: var RunningStat, b: RunningStat) {.inline.} =
  ## Adds the `RunningStat` `b` to `a`.
  a = a + b

proc `$`*(a: RunningStat): string =
  ## Produces a string representation of the `RunningStat`. The exact
  ## format is currently unspecified and subject to change. Currently
  ## it contains:
  ##
  ## - the number of probes
  ## - min, max values
  ## - sum, mean and standard deviation.
  result = "RunningStat(\n"
  result.add "  number of probes: " & $a.n & "\n"
  result.add "  max: " & $a.max & "\n"
  result.add "  min: " & $a.min & "\n"
  result.add "  sum: " & $a.sum & "\n"
  result.add "  mean: " & $a.mean & "\n"
  result.add "  std deviation: " & $a.standardDeviation & "\n"
  result.add ")"

# ---------------------- standalone array/seq stats ---------------------

proc mean*[T](x: openArray[T]): float =
  ## Computes the mean of `x`.
  var rs: RunningStat
  rs.push(x)
  result = rs.mean()

proc variance*[T](x: openArray[T]): float =
  ## Computes the population variance of `x`.
  var rs: RunningStat
  rs.push(x)
  result = rs.variance()

proc varianceS*[T](x: openArray[T]): float =
  ## Computes the sample variance of `x`.
  var rs: RunningStat
  rs.push(x)
  result = rs.varianceS()

proc standardDeviation*[T](x: openArray[T]): float =
  ## Computes the population standard deviation of `x`.
  var rs: RunningStat
  rs.push(x)
  result = rs.standardDeviation()

proc standardDeviationS*[T](x: openArray[T]): float =
  ## Computes the sample standard deviation of `x`.
  var rs: RunningStat
  rs.push(x)
  result = rs.standardDeviationS()

proc skewness*[T](x: openArray[T]): float =
  ## Computes the population skewness of `x`.
  var rs: RunningStat
  rs.push(x)
  result = rs.skewness()

proc skewnessS*[T](x: openArray[T]): float =
  ## Computes the sample skewness of `x`.
  var rs: RunningStat
  rs.push(x)
  result = rs.skewnessS()

proc kurtosis*[T](x: openArray[T]): float =
  ## Computes the population kurtosis of `x`.
  var rs: RunningStat
  rs.push(x)
  result = rs.kurtosis()

proc kurtosisS*[T](x: openArray[T]): float =
  ## Computes the sample kurtosis of `x`.
  var rs: RunningStat
  rs.push(x)
  result = rs.kurtosisS()

import std/random

# Partition using Lomuto partition scheme
proc partition[T](arr: var openArray[T], K: Natural,
                  myCmp: proc(x, y: T): int): int =
  let
    left= arr.low
    right= arr.high
    pivot = arr[K]

  var pInd = K # Pick `pIndex` as a pivot from the list
  if pInd != right: swap(arr[pInd], arr[right]) # Move pivot to end
  
  #[
    elements less than the pivot will be pushed to the left of `pIndex`;
    elements more than the pivot will be pushed to the right of `pIndex`;
    equal elements can go either way  ]#

  pInd = left
  #[ each time we find an element less than or equal to the pivot, `pInd`
    is incremented, and that element would be placed before the pivot. ]#

  for i in left ..< right:
    if myCmp(arr[i], pivot) <= 0: # arr[i] <= pivot
      if i != pInd: swap(arr[i], arr[pInd])
      inc(pInd)

  # Move pivot to its place
  if pInd < right: swap(arr[pInd], arr[right])

  result = pInd # arr[i] <= pivot  for i in left..pInd


proc quickSelect*[T](arr: var openArray[T], left, right, K: Natural,
                     myCmp: proc(x, y: T): int {.nimcall.} = cmp[T]): T =
  ##[
    Returns the ``K``'th smallest element in a list within `left / right`
    (i.e., ``left <= K <= right``).
    
    If ``K == left`` the smallest element, and 
    if ``K == right`` the largest element of **arr** will be returned.
    
    .. warning:: `arr` will be modified in general
  ]##

  assert(left <= K and K <= right)
  # If the list contains only one element, return that element
  if left == right: return arr[left]

  # select `pInd` between left and right
  var pInd = left + rand(right-left)
  pInd = partition(arr, pInd, myCmp)

  # The pivot is in its sorted position
  if K == pInd: 
    result= arr[K]

  elif K < pInd: # if K is less than the pivot index
    result= quickSelect(arr, left, pInd-1, K, myCmp)

  # if K is greater than the pivot index
  else:
    result= quickSelect(arr, pInd+1, right, K, myCmp)

type MedianMode* = enum
  mdlow, mdhigh

proc median*[T](arr: var openArray[T], Mode:MedianMode,
                myCmp: proc(x, y: T): int {.nimcall.} = cmp[T]): T =
  ##[
  The **median** `M` of an array/sequence of comparable items is defined such that 
  
  in case the array/sequence has *odd* length : 
     ``(m-1)/2`` elements are lower or equal and 
     ``(m-1)/2`` elements are higher or equal than `M` .

     In this case  ``Mode == mdlow`` and ``Mode == mdhigh`` give the same result.

  in case the array/sequence has *even* length the median is only defined for
     arrays of `SomeNumber` elements - see below -

     In general **Mode == mdlow** has the property that 
     ``m/2``   elements are less than or equal this value  and
     ``m/2+1`` elements are greater than or equal this value.

     **Mode == mdhigh** has the property that 
     ``m/2``   elements are greater or equal than this value and
     ``m/2+1`` elements are less or equal than this value.

  .. warning:: `arr` will be modified in general
  ]##
  let
    left= arr.low
    right= arr.high

  if  Mode == mdlow :
    quickSelect(arr, left, right, (right+left) div 2, myCmp)
  else :
    quickSelect(arr, left, right, (right+left+1) div 2, myCmp)


proc median*[T: SomeNumber](arr: var openArray[T],
             myCmp: proc(x, y: T): int {.nimcall.} = cmp[T]): float =
  ##[This is a special version which returns a float value.
    If the length of `arr` is *even*, it returns
    
    ``float( median(arr,mdlow,myCmp) + median(arr,mdhigh,myCmp) )*0.5``

  .. warning:: `arr` will be modified in general
  ]##

  let
    N = arr.len
    K = arr.low + (N-1) div 2

  if (N and 1) == 1: # N is odd
    result = float(quickSelect(arr, arr.low, arr.high, K, myCmp))
  else:
    result = float(quickSelect(arr, arr.low, arr.high, K, myCmp) +
                   quickSelect(arr, arr.low, arr.high, K+1, myCmp))*0.5


# ---------------------- Running Regression -----------------------------

proc clear*(r: var RunningRegress) =
  ## Resets `r`.
  r.x_stats.clear()
  r.y_stats.clear()
  r.s_xy = 0.0
  r.n = 0

proc push*(r: var RunningRegress, x, y: float) =
  ## Pushes two values `x` and `y` for processing.
  r.s_xy += (r.x_stats.mean() - x)*(r.y_stats.mean() - y) *
                toFloat(r.n) / toFloat(r.n + 1)
  r.x_stats.push(x)
  r.y_stats.push(y)
  inc(r.n)

proc push*(r: var RunningRegress, x, y: int) {.inline.} =
  ## Pushes two values `x` and `y` for processing.
  ##
  ## `x` and `y` are converted to `float`
  ## and the other push operation is called.
  r.push(toFloat(x), toFloat(y))

proc push*(r: var RunningRegress, x, y: openArray[float|int]) =
  ## Pushes two sets of values `x` and `y` for processing.
  assert(x.len == y.len)
  for i in 0..<x.len:
    r.push(x[i], y[i])

proc slope*(r: RunningRegress): float =
  ## Computes the current slope of `r`.
  let s_xx = r.x_stats.varianceS()*toFloat(r.n - 1)
  result = r.s_xy / s_xx

proc intercept*(r: RunningRegress): float =
  ## Computes the current intercept of `r`.
  result = r.y_stats.mean() - r.slope()*r.x_stats.mean()

proc correlation*(r: RunningRegress): float =
  ## Computes the current correlation of the two data
  ## sets pushed into `r`.
  let t = r.x_stats.standardDeviation() * r.y_stats.standardDeviation()
  result = r.s_xy / (toFloat(r.n) * t)

proc `+`*(a, b: RunningRegress): RunningRegress =
  ## Combines two `RunningRegress` objects.
  ##
  ## Useful when performing parallel analysis of data series
  ## and needing to re-combine parallel result sets
  result.clear()
  result.x_stats = a.x_stats + b.x_stats
  result.y_stats = a.y_stats + b.y_stats
  result.n = a.n + b.n

  let delta_x = b.x_stats.mean() - a.x_stats.mean()
  let delta_y = b.y_stats.mean() - a.y_stats.mean()
  result.s_xy = a.s_xy + b.s_xy +
      toFloat(a.n*b.n)*delta_x*delta_y/toFloat(result.n)

proc `+=`*(a: var RunningRegress, b: RunningRegress) =
  ## Adds the `RunningRegress` `b` to `a`.
  a = a + b

{.pop.}
{.pop.}
