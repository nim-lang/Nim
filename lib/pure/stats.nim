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
## The data is analysed in a single pass, when a data value
## is pushed to the ``RunningStat`` or ``RunningRegress`` objects
##
## ``RunningStat`` calculates for a single data set
## - n (data count)
## - min  (smallest value)
## - max  (largest value)
## - sum
## - mean
## - variance
## - varianceS (sample var)
## - standardDeviation
## - standardDeviationS  (sample stddev)
## - skewness (the third statistical moment)
## - kurtosis (the fourth statistical moment)
##
## ``RunningRegress`` calculates for two sets of data
## - n
## - slope
## - intercept
## - correlation
##
## Procs have been provided to calculate statistics on arrays and sequences.
##
## However, if more than a single statistical calculation is required, it is more
## efficient to push the data once to the RunningStat object, and
## call the numerous statistical procs for the RunningStat object.
##
## .. code-block:: Nim
##
##  var rs: RunningStat
##  rs.push(MySeqOfData)
##  rs.mean()
##  rs.variance()
##  rs.skewness()
##  rs.kurtosis()

from math import FloatClass, sqrt, pow, round

{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!
{.push checks:off, line_dir:off, stack_trace:off.}

type
  RunningStat* = object             ## an accumulator for statistical data
    n*: int                         ## number of pushed data
    min*, max*, sum*: float         ## self-explaining
    mom1, mom2, mom3, mom4: float   ## statistical moments, mom1 is mean


  RunningRegress* = object  ## an accumulator for regression calculations
    n*: int                 ## number of pushed data
    x_stats*: RunningStat   ## stats for first set of data
    y_stats*: RunningStat   ## stats for second set of data
    s_xy: float             ## accumulated data for combined xy

# ----------- RunningStat --------------------------
proc clear*(s: var RunningStat) =
  ## reset `s`
  s.n = 0
  s.min = toBiggestFloat(int.high)
  s.max = 0.0
  s.sum = 0.0
  s.mom1 = 0.0
  s.mom2 = 0.0
  s.mom3 = 0.0
  s.mom4 = 0.0

proc push*(s: var RunningStat, x: float) =
  ## pushes a value `x` for processing
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
  ## pushes a value `x` for processing.
  ##
  ## `x` is simply converted to ``float``
  ## and the other push operation is called.
  s.push(toFloat(x))

proc push*(s: var RunningStat, x: openarray[float|int]) =
  ## pushes all values of `x` for processing.
  ##
  ## Int values of `x` are simply converted to ``float`` and
  ## the other push operation is called.
  for val in x:
    s.push(val)

proc mean*(s: RunningStat): float =
  ## computes the current mean of `s`
  result = s.mom1

proc variance*(s: RunningStat): float =
  ## computes the current population variance of `s`
  result = s.mom2 / toFloat(s.n)

proc varianceS*(s: RunningStat): float =
  ## computes the current sample variance of `s`
  if s.n > 1: result = s.mom2 / toFloat(s.n - 1)

proc standardDeviation*(s: RunningStat): float =
  ## computes the current population standard deviation of `s`
  result = sqrt(variance(s))

proc standardDeviationS*(s: RunningStat): float =
  ## computes the current sample standard deviation of `s`
  result = sqrt(varianceS(s))

proc skewness*(s: RunningStat): float =
  ## computes the current population skewness of `s`
  result = sqrt(toFloat(s.n)) * s.mom3 / pow(s.mom2, 1.5)

proc skewnessS*(s: RunningStat): float =
  ## computes the current sample skewness of `s`
  let s2 = skewness(s)
  result = sqrt(toFloat(s.n*(s.n-1)))*s2 / toFloat(s.n-2)

proc kurtosis*(s: RunningStat): float =
  ## computes the current population kurtosis of `s`
  result = toFloat(s.n) * s.mom4 / (s.mom2 * s.mom2) - 3.0

proc kurtosisS*(s: RunningStat): float =
  ## computes the current sample kurtosis of `s`
  result = toFloat(s.n-1) / toFloat((s.n-2)*(s.n-3)) *
              (toFloat(s.n+1)*kurtosis(s) + 6)

proc `+`*(a, b: RunningStat): RunningStat =
  ## combine two RunningStats.
  ##
  ## Useful if performing parallel analysis of data series
  ## and need to re-combine parallel result sets
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
  ## add a second RunningStats `b` to `a`
  a = a + b

proc `$`*(a: RunningStat): string =
  ## produces a string representation of the ``RunningStat``. The exact
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
  ## computes the mean of `x`
  var rs: RunningStat
  rs.push(x)
  result = rs.mean()

proc variance*[T](x: openArray[T]): float =
  ## computes the population variance of `x`
  var rs: RunningStat
  rs.push(x)
  result = rs.variance()

proc varianceS*[T](x: openArray[T]): float =
  ## computes the sample variance of `x`
  var rs: RunningStat
  rs.push(x)
  result = rs.varianceS()

proc standardDeviation*[T](x: openArray[T]): float =
  ## computes the population standardDeviation of `x`
  var rs: RunningStat
  rs.push(x)
  result = rs.standardDeviation()

proc standardDeviationS*[T](x: openArray[T]): float =
  ## computes the sample standardDeviation of `x`
  var rs: RunningStat
  rs.push(x)
  result = rs.standardDeviationS()

proc skewness*[T](x: openArray[T]): float =
  ## computes the population skewness of `x`
  var rs: RunningStat
  rs.push(x)
  result = rs.skewness()

proc skewnessS*[T](x: openArray[T]): float =
  ## computes the sample skewness of `x`
  var rs: RunningStat
  rs.push(x)
  result = rs.skewnessS()

proc kurtosis*[T](x: openArray[T]): float =
  ## computes the population kurtosis of `x`
  var rs: RunningStat
  rs.push(x)
  result = rs.kurtosis()

proc kurtosisS*[T](x: openArray[T]): float =
  ## computes the sample kurtosis of `x`
  var rs: RunningStat
  rs.push(x)
  result = rs.kurtosisS()

# ---------------------- Running Regression -----------------------------

proc clear*(r: var RunningRegress) =
  ## reset `r`
  r.x_stats.clear()
  r.y_stats.clear()
  r.s_xy = 0.0
  r.n = 0

proc push*(r: var RunningRegress, x, y: float) =
  ## pushes two values `x` and `y` for processing
  r.s_xy += (r.x_stats.mean() - x)*(r.y_stats.mean() - y)*
                toFloat(r.n) / toFloat(r.n + 1)
  r.x_stats.push(x)
  r.y_stats.push(y)
  inc(r.n)

proc push*(r: var RunningRegress, x, y: int) {.inline.} =
  ## pushes two values `x` and `y` for processing.
  ##
  ## `x` and `y` are converted to ``float``
  ## and the other push operation is called.
  r.push(toFloat(x), toFloat(y))

proc push*(r: var RunningRegress, x, y: openarray[float|int]) =
  ## pushes two sets of values `x` and `y` for processing.
  assert(x.len == y.len)
  for i in 0..<x.len:
    r.push(x[i], y[i])

proc slope*(r: RunningRegress): float =
  ## computes the current slope of `r`
  let s_xx = r.x_stats.varianceS()*toFloat(r.n - 1)
  result = r.s_xy / s_xx

proc intercept*(r: RunningRegress): float =
  ## computes the current intercept of `r`
  result = r.y_stats.mean() - r.slope()*r.x_stats.mean()

proc correlation*(r: RunningRegress): float =
  ## computes the current correlation of the two data
  ## sets pushed into `r`
  let t = r.x_stats.standardDeviation() * r.y_stats.standardDeviation()
  result = r.s_xy / ( toFloat(r.n) * t )

proc `+`*(a, b: RunningRegress): RunningRegress =
  ## combine two `RunningRegress` objects.
  ##
  ## Useful if performing parallel analysis of data series
  ## and need to re-combine parallel result sets
  result.clear()
  result.x_stats = a.x_stats + b.x_stats
  result.y_stats = a.y_stats + b.y_stats
  result.n = a.n + b.n

  let delta_x = b.x_stats.mean() - a.x_stats.mean()
  let delta_y = b.y_stats.mean() - a.y_stats.mean()
  result.s_xy = a.s_xy + b.s_xy +
      toFloat(a.n*b.n)*delta_x*delta_y/toFloat(result.n)

proc `+=`*(a: var RunningRegress, b: RunningRegress) =
  ## add RunningRegress `b` to `a`
  a = a + b

{.pop.}
{.pop.}

when isMainModule:
  proc clean(x: float): float =
    result = round(1.0e8*x).float * 1.0e-8

  var rs: RunningStat
  rs.push(@[1.0, 2.0, 1.0, 4.0, 1.0, 4.0, 1.0, 2.0])
  doAssert(rs.n == 8)
  doAssert(clean(rs.mean) == 2.0)
  doAssert(clean(rs.variance()) == 1.5)
  doAssert(clean(rs.varianceS()) == 1.71428571)
  doAssert(clean(rs.skewness()) == 0.81649658)
  doAssert(clean(rs.skewnessS()) == 1.01835015)
  doAssert(clean(rs.kurtosis()) == -1.0)
  doAssert(clean(rs.kurtosisS()) == -0.7000000000000001)

  var rs1, rs2: RunningStat
  rs1.push(@[1.0, 2.0, 1.0, 4.0])
  rs2.push(@[1.0, 4.0, 1.0, 2.0])
  let rs3 = rs1 + rs2
  doAssert(clean(rs3.mom2) == clean(rs.mom2))
  doAssert(clean(rs3.mom3) == clean(rs.mom3))
  doAssert(clean(rs3.mom4) == clean(rs.mom4))
  rs1 += rs2
  doAssert(clean(rs1.mom2) == clean(rs.mom2))
  doAssert(clean(rs1.mom3) == clean(rs.mom3))
  doAssert(clean(rs1.mom4) == clean(rs.mom4))
  rs1.clear()
  rs1.push(@[1.0, 2.2, 1.4, 4.9])
  doAssert(rs1.sum == 9.5)
  doAssert(rs1.mean() == 2.375)

  when not defined(cpu32):
    # XXX For some reason on 32bit CPUs these results differ
    var rr: RunningRegress
    rr.push(@[0.0,1.0,2.8,3.0,4.0], @[0.0,1.0,2.3,3.0,4.0])
    doAssert(rr.slope() == 0.9695585996955861)
    doAssert(rr.intercept() == -0.03424657534246611)
    doAssert(rr.correlation() == 0.9905100362239381)
    var rr1, rr2: RunningRegress
    rr1.push(@[0.0,1.0], @[0.0,1.0])
    rr2.push(@[2.8,3.0,4.0], @[2.3,3.0,4.0])
    let rr3 = rr1 + rr2
    doAssert(rr3.correlation() == rr.correlation())
    doAssert(clean(rr3.slope()) == clean(rr.slope()))
    doAssert(clean(rr3.intercept()) == clean(rr.intercept()))
