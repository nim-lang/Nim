#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## *Constructive mathematics is naturally typed.* -- Simon Thompson
##
## Basic math routines for Nim.
##
## Note that the trigonometric functions naturally operate on radians.
## The helper functions `degToRad<#degToRad,T>`_ and `radToDeg<#radToDeg,T>`_
## provide conversion between radians and degrees.
##
## .. code-block::
##
##   import math
##   from sequtils import map
##
##   let a = [0.0, PI/6, PI/4, PI/3, PI/2]
##
##   echo a.map(sin)
##   # @[0.0, 0.499…, 0.707…, 0.866…, 1.0]
##
##   echo a.map(tan)
##   # @[0.0, 0.577…, 0.999…, 1.732…, 1.633…e+16]
##
##   echo cos(degToRad(180.0))
##   # -1.0
##
##   echo sqrt(-1.0)
##   # nan   (use `complex` module)
##
## This module is available for the `JavaScript target
## <backends.html#backends-the-javascript-target>`_.
##
## **See also:**
## * `complex module<complex.html>`_ for complex numbers and their
##   mathematical operations
## * `rationals module<rationals.html>`_ for rational numbers and their
##   mathematical operations
## * `fenv module<fenv.html>`_ for handling of floating-point rounding
##   and exceptions (overflow, zero-divide, etc.)
## * `random module<random.html>`_ for fast and tiny random number generator
## * `mersenne module<mersenne.html>`_ for Mersenne twister random number generator
## * `stats module<stats.html>`_ for statistical analysis
## * `strformat module<strformat.html>`_ for formatting floats for print
## * `system module<system.html>`_ Some very basic and trivial math operators
##   are on system directly, to name a few ``shr``, ``shl``, ``xor``, ``clamp``, etc.


import std/private/since
{.push debugger: off.} # the user does not want to trace a part
                       # of the standard library!

import bitops

proc binom*(n, k: int): int {.noSideEffect.} =
  ## Computes the `binomial coefficient <https://en.wikipedia.org/wiki/Binomial_coefficient>`_.
  runnableExamples:
    doAssert binom(6, 2) == binom(6, 4)
    doAssert binom(6, 2) == 15
    doAssert binom(-6, 2) == 1
    doAssert binom(6, 0) == 1
  if k <= 0: return 1
  if 2*k > n: return binom(n, n-k)
  result = n
  for i in countup(2, k):
    result = (result * (n + 1 - i)) div i

proc createFactTable[N: static[int]]: array[N, int] =
  result[0] = 1
  for i in 1 ..< N:
    result[i] = result[i - 1] * i

proc fac*(n: int): int =
  ## Computes the `factorial <https://en.wikipedia.org/wiki/Factorial>`_ of
  ## a non-negative integer ``n``.
  ##
  ## See also:
  ## * `prod proc <#prod,openArray[T]>`_
  runnableExamples:
    doAssert fac(3) == 6
    doAssert fac(4) == 24
    doAssert fac(10) == 3628800
  const factTable =
    when sizeof(int) == 2:
      createFactTable[5]()
    elif sizeof(int) == 4:
      createFactTable[13]()
    else:
      createFactTable[21]()
  assert(n >= 0, $n & " must not be negative.")
  assert(n < factTable.len, $n & " is too large to look up in the table")
  factTable[n]

{.push checks: off, line_dir: off, stack_trace: off.}

when defined(Posix) and not defined(genode):
  {.passl: "-lm".}

const
  PI* = 3.1415926535897932384626433          ## The circle constant PI (Ludolph's number)
  TAU* = 2.0 * PI                            ## The circle constant TAU (= 2 * PI)
  E* = 2.71828182845904523536028747          ## Euler's number

  MaxFloat64Precision* = 16                  ## Maximum number of meaningful digits
                                             ## after the decimal point for Nim's
                                             ## ``float64`` type.
  MaxFloat32Precision* = 8                   ## Maximum number of meaningful digits
                                             ## after the decimal point for Nim's
                                             ## ``float32`` type.
  MaxFloatPrecision* = MaxFloat64Precision   ## Maximum number of
                                             ## meaningful digits
                                             ## after the decimal point
                                             ## for Nim's ``float`` type.
  MinFloatNormal* = 2.225073858507201e-308   ## Smallest normal number for Nim's
                                             ## ``float`` type. (= 2^-1022).
  RadPerDeg = PI / 180.0                     ## Number of radians per degree

type
  FloatClass* = enum ## Describes the class a floating point value belongs to.
                     ## This is the type that is returned by
                     ## `classify proc <#classify,float>`_.
    fcNormal,        ## value is an ordinary nonzero floating point value
    fcSubnormal,     ## value is a subnormal (a very small) floating point value
    fcZero,          ## value is zero
    fcNegZero,       ## value is the negative zero
    fcNan,           ## value is Not-A-Number (NAN)
    fcInf,           ## value is positive infinity
    fcNegInf         ## value is negative infinity

proc classify*(x: float): FloatClass =
  ## Classifies a floating point value.
  ##
  ## Returns ``x``'s class as specified by `FloatClass enum<#FloatClass>`_.
  runnableExamples:
    doAssert classify(0.3) == fcNormal
    doAssert classify(0.0) == fcZero
    doAssert classify(0.3/0.0) == fcInf
    doAssert classify(-0.3/0.0) == fcNegInf
    doAssert classify(5.0e-324) == fcSubnormal

  # JavaScript and most C compilers have no classify:
  if x == 0.0:
    if 1.0/x == Inf:
      return fcZero
    else:
      return fcNegZero
  if x*0.5 == x:
    if x > 0.0: return fcInf
    else: return fcNegInf
  if x != x: return fcNan
  if abs(x) < MinFloatNormal:
    return fcSubnormal
  return fcNormal

proc isPowerOfTwo*(x: int): bool {.noSideEffect.} =
  ## Returns ``true``, if ``x`` is a power of two, ``false`` otherwise.
  ##
  ## Zero and negative numbers are not a power of two.
  ##
  ## See also:
  ## * `nextPowerOfTwo proc<#nextPowerOfTwo,int>`_
  runnableExamples:
    doAssert isPowerOfTwo(16) == true
    doAssert isPowerOfTwo(5) == false
    doAssert isPowerOfTwo(0) == false
    doAssert isPowerOfTwo(-16) == false
  return (x > 0) and ((x and (x - 1)) == 0)

proc nextPowerOfTwo*(x: int): int {.noSideEffect.} =
  ## Returns ``x`` rounded up to the nearest power of two.
  ##
  ## Zero and negative numbers get rounded up to 1.
  ##
  ## See also:
  ## * `isPowerOfTwo proc<#isPowerOfTwo,int>`_
  runnableExamples:
    doAssert nextPowerOfTwo(16) == 16
    doAssert nextPowerOfTwo(5) == 8
    doAssert nextPowerOfTwo(0) == 1
    doAssert nextPowerOfTwo(-16) == 1
  result = x - 1
  when defined(cpu64):
    result = result or (result shr 32)
  when sizeof(int) > 2:
    result = result or (result shr 16)
  when sizeof(int) > 1:
    result = result or (result shr 8)
  result = result or (result shr 4)
  result = result or (result shr 2)
  result = result or (result shr 1)
  result += 1 + ord(x <= 0)

proc sum*[T](x: openArray[T]): T {.noSideEffect.} =
  ## Computes the sum of the elements in ``x``.
  ##
  ## If ``x`` is empty, 0 is returned.
  ##
  ## See also:
  ## * `prod proc <#prod,openArray[T]>`_
  ## * `cumsum proc <#cumsum,openArray[T]>`_
  ## * `cumsummed proc <#cumsummed,openArray[T]>`_
  runnableExamples:
    doAssert sum([1, 2, 3, 4]) == 10
    doAssert sum([-1.5, 2.7, -0.1]) == 1.1
  for i in items(x): result = result + i

proc prod*[T](x: openArray[T]): T {.noSideEffect.} =
  ## Computes the product of the elements in ``x``.
  ##
  ## If ``x`` is empty, 1 is returned.
  ##
  ## See also:
  ## * `sum proc <#sum,openArray[T]>`_
  ## * `fac proc <#fac,int>`_
  runnableExamples:
    doAssert prod([1, 2, 3, 4]) == 24
    doAssert prod([-4, 3, 5]) == -60
  result = 1.T
  for i in items(x): result = result * i

proc cumsummed*[T](x: openArray[T]): seq[T] =
  ## Return cumulative (aka prefix) summation of ``x``.
  ##
  ## See also:
  ## * `sum proc <#sum,openArray[T]>`_
  ## * `cumsum proc <#cumsum,openArray[T]>`_ for the in-place version
  runnableExamples:
    let a = [1, 2, 3, 4]
    doAssert cumsummed(a) == @[1, 3, 6, 10]
  result.setLen(x.len)
  result[0] = x[0]
  for i in 1 ..< x.len: result[i] = result[i-1] + x[i]

proc cumsum*[T](x: var openArray[T]) =
  ## Transforms ``x`` in-place (must be declared as `var`) into its
  ## cumulative (aka prefix) summation.
  ##
  ## See also:
  ## * `sum proc <#sum,openArray[T]>`_
  ## * `cumsummed proc <#cumsummed,openArray[T]>`_ for a version which
  ##   returns cumsummed sequence
  runnableExamples:
    var a = [1, 2, 3, 4]
    cumsum(a)
    doAssert a == @[1, 3, 6, 10]
  for i in 1 ..< x.len: x[i] = x[i-1] + x[i]

{.push noSideEffect.}
when not defined(js): # C
  proc sqrt*(x: float32): float32 {.importc: "sqrtf", header: "<math.h>".}
  proc sqrt*(x: float64): float64 {.importc: "sqrt", header: "<math.h>".}
    ## Computes the square root of ``x``.
    ##
    ## See also:
    ## * `cbrt proc <#cbrt,float64>`_ for cubic root
    ##
    ## .. code-block:: nim
    ##  echo sqrt(4.0)  ## 2.0
    ##  echo sqrt(1.44) ## 1.2
    ##  echo sqrt(-4.0) ## nan
  proc cbrt*(x: float32): float32 {.importc: "cbrtf", header: "<math.h>".}
  proc cbrt*(x: float64): float64 {.importc: "cbrt", header: "<math.h>".}
    ## Computes the cubic root of ``x``.
    ##
    ## See also:
    ## * `sqrt proc <#sqrt,float64>`_ for square root
    ##
    ## .. code-block:: nim
    ##  echo cbrt(8.0)   ## 2.0
    ##  echo cbrt(2.197) ## 1.3
    ##  echo cbrt(-27.0) ## -3.0
  proc ln*(x: float32): float32 {.importc: "logf", header: "<math.h>".}
  proc ln*(x: float64): float64 {.importc: "log", header: "<math.h>".}
    ## Computes the `natural logarithm <https://en.wikipedia.org/wiki/Natural_logarithm>`_
    ## of ``x``.
    ##
    ## See also:
    ## * `log proc <#log,T,T>`_
    ## * `log10 proc <#log10,float64>`_
    ## * `log2 proc <#log2,float64>`_
    ## * `exp proc <#exp,float64>`_
    ##
    ## .. code-block:: nim
    ##  echo ln(exp(4.0)) ## 4.0
    ##  echo ln(1.0))     ## 0.0
    ##  echo ln(0.0)      ## -inf
    ##  echo ln(-7.0)     ## nan
else: # JS
  proc sqrt*(x: float32): float32 {.importc: "Math.sqrt", nodecl.}
  proc sqrt*(x: float64): float64 {.importc: "Math.sqrt", nodecl.}

  proc cbrt*(x: float32): float32 {.importc: "Math.cbrt", nodecl.}
  proc cbrt*(x: float64): float64 {.importc: "Math.cbrt", nodecl.}

  proc ln*(x: float32): float32 {.importc: "Math.log", nodecl.}
  proc ln*(x: float64): float64 {.importc: "Math.log", nodecl.}

proc log*[T: SomeFloat](x, base: T): T =
  ## Computes the logarithm of ``x`` to base ``base``.
  ##
  ## See also:
  ## * `ln proc <#ln,float64>`_
  ## * `log10 proc <#log10,float64>`_
  ## * `log2 proc <#log2,float64>`_
  ## * `exp proc <#exp,float64>`_
  ##
  ## .. code-block:: nim
  ##  echo log(9.0, 3.0)  ## 2.0
  ##  echo log(32.0, 2.0) ## 5.0
  ##  echo log(0.0, 2.0)  ## -inf
  ##  echo log(-7.0, 4.0) ## nan
  ##  echo log(8.0, -2.0) ## nan
  ln(x) / ln(base)

when not defined(js): # C
  proc log10*(x: float32): float32 {.importc: "log10f", header: "<math.h>".}
  proc log10*(x: float64): float64 {.importc: "log10", header: "<math.h>".}
    ## Computes the common logarithm (base 10) of ``x``.
    ##
    ## See also:
    ## * `ln proc <#ln,float64>`_
    ## * `log proc <#log,T,T>`_
    ## * `log2 proc <#log2,float64>`_
    ## * `exp proc <#exp,float64>`_
    ##
    ## .. code-block:: nim
    ##  echo log10(100.0)  ## 2.0
    ##  echo log10(0.0)    ## nan
    ##  echo log10(-100.0) ## -inf
  proc exp*(x: float32): float32 {.importc: "expf", header: "<math.h>".}
  proc exp*(x: float64): float64 {.importc: "exp", header: "<math.h>".}
    ## Computes the exponential function of ``x`` (e^x).
    ##
    ## See also:
    ## * `ln proc <#ln,float64>`_
    ## * `log proc <#log,T,T>`_
    ## * `log10 proc <#log10,float64>`_
    ## * `log2 proc <#log2,float64>`_
    ##
    ## .. code-block:: nim
    ##  echo exp(1.0)     ## 2.718281828459045
    ##  echo ln(exp(4.0)) ## 4.0
    ##  echo exp(0.0)     ## 1.0
    ##  echo exp(-1.0)    ## 0.3678794411714423
  proc sin*(x: float32): float32 {.importc: "sinf", header: "<math.h>".}
  proc sin*(x: float64): float64 {.importc: "sin", header: "<math.h>".}
    ## Computes the sine of ``x``.
    ##
    ## See also:
    ## * `cos proc <#cos,float64>`_
    ## * `tan proc <#tan,float64>`_
    ## * `arcsin proc <#arcsin,float64>`_
    ## * `sinh proc <#sinh,float64>`_
    ##
    ## .. code-block:: nim
    ##  echo sin(PI / 6)         ## 0.4999999999999999
    ##  echo sin(degToRad(90.0)) ## 1.0
  proc cos*(x: float32): float32 {.importc: "cosf", header: "<math.h>".}
  proc cos*(x: float64): float64 {.importc: "cos", header: "<math.h>".}
    ## Computes the cosine of ``x``.
    ##
    ## See also:
    ## * `sin proc <#sin,float64>`_
    ## * `tan proc <#tan,float64>`_
    ## * `arccos proc <#arccos,float64>`_
    ## * `cosh proc <#cosh,float64>`_
    ##
    ## .. code-block:: nim
    ##  echo cos(2 * PI)         ## 1.0
    ##  echo cos(degToRad(60.0)) ## 0.5000000000000001
  proc tan*(x: float32): float32 {.importc: "tanf", header: "<math.h>".}
  proc tan*(x: float64): float64 {.importc: "tan", header: "<math.h>".}
    ## Computes the tangent of ``x``.
    ##
    ## See also:
    ## * `sin proc <#sin,float64>`_
    ## * `cos proc <#cos,float64>`_
    ## * `arctan proc <#arctan,float64>`_
    ## * `tanh proc <#tanh,float64>`_
    ##
    ## .. code-block:: nim
    ##  echo tan(degToRad(45.0)) ## 0.9999999999999999
    ##  echo tan(PI / 4)         ## 0.9999999999999999
  proc sinh*(x: float32): float32 {.importc: "sinhf", header: "<math.h>".}
  proc sinh*(x: float64): float64 {.importc: "sinh", header: "<math.h>".}
    ## Computes the `hyperbolic sine <https://en.wikipedia.org/wiki/Hyperbolic_function#Definitions>`_ of ``x``.
    ##
    ## See also:
    ## * `cosh proc <#cosh,float64>`_
    ## * `tanh proc <#tanh,float64>`_
    ## * `arcsinh proc <#arcsinh,float64>`_
    ## * `sin proc <#sin,float64>`_
    ##
    ## .. code-block:: nim
    ##  echo sinh(0.0)            ## 0.0
    ##  echo sinh(1.0)            ## 1.175201193643801
    ##  echo sinh(degToRad(90.0)) ## 2.301298902307295
  proc cosh*(x: float32): float32 {.importc: "coshf", header: "<math.h>".}
  proc cosh*(x: float64): float64 {.importc: "cosh", header: "<math.h>".}
    ## Computes the `hyperbolic cosine <https://en.wikipedia.org/wiki/Hyperbolic_function#Definitions>`_ of ``x``.
    ##
    ## See also:
    ## * `sinh proc <#sinh,float64>`_
    ## * `tanh proc <#tanh,float64>`_
    ## * `arccosh proc <#arccosh,float64>`_
    ## * `cos proc <#cos,float64>`_
    ##
    ## .. code-block:: nim
    ##  echo cosh(0.0)            ## 1.0
    ##  echo cosh(1.0)            ## 1.543080634815244
    ##  echo cosh(degToRad(90.0)) ## 2.509178478658057
  proc tanh*(x: float32): float32 {.importc: "tanhf", header: "<math.h>".}
  proc tanh*(x: float64): float64 {.importc: "tanh", header: "<math.h>".}
    ## Computes the `hyperbolic tangent <https://en.wikipedia.org/wiki/Hyperbolic_function#Definitions>`_ of ``x``.
    ##
    ## See also:
    ## * `sinh proc <#sinh,float64>`_
    ## * `cosh proc <#cosh,float64>`_
    ## * `arctanh proc <#arctanh,float64>`_
    ## * `tan proc <#tan,float64>`_
    ##
    ## .. code-block:: nim
    ##  echo tanh(0.0)            ## 0.0
    ##  echo tanh(1.0)            ## 0.7615941559557649
    ##  echo tanh(degToRad(90.0)) ## 0.9171523356672744

  proc arccos*(x: float32): float32 {.importc: "acosf", header: "<math.h>".}
  proc arccos*(x: float64): float64 {.importc: "acos", header: "<math.h>".}
    ## Computes the arc cosine of ``x``.
    ##
    ## See also:
    ## * `arcsin proc <#arcsin,float64>`_
    ## * `arctan proc <#arctan,float64>`_
    ## * `arctan2 proc <#arctan2,float64,float64>`_
    ## * `cos proc <#cos,float64>`_
    ##
    ## .. code-block:: nim
    ##  echo radToDeg(arccos(0.0)) ## 90.0
    ##  echo radToDeg(arccos(1.0)) ## 0.0
  proc arcsin*(x: float32): float32 {.importc: "asinf", header: "<math.h>".}
  proc arcsin*(x: float64): float64 {.importc: "asin", header: "<math.h>".}
    ## Computes the arc sine of ``x``.
    ##
    ## See also:
    ## * `arccos proc <#arccos,float64>`_
    ## * `arctan proc <#arctan,float64>`_
    ## * `arctan2 proc <#arctan2,float64,float64>`_
    ## * `sin proc <#sin,float64>`_
    ##
    ## .. code-block:: nim
    ##  echo radToDeg(arcsin(0.0)) ## 0.0
    ##  echo radToDeg(arcsin(1.0)) ## 90.0
  proc arctan*(x: float32): float32 {.importc: "atanf", header: "<math.h>".}
  proc arctan*(x: float64): float64 {.importc: "atan", header: "<math.h>".}
    ## Calculate the arc tangent of ``x``.
    ##
    ## See also:
    ## * `arcsin proc <#arcsin,float64>`_
    ## * `arccos proc <#arccos,float64>`_
    ## * `arctan2 proc <#arctan2,float64,float64>`_
    ## * `tan proc <#tan,float64>`_
    ##
    ## .. code-block:: nim
    ##  echo arctan(1.0) ## 0.7853981633974483
    ##  echo radToDeg(arctan(1.0)) ## 45.0
  proc arctan2*(y, x: float32): float32 {.importc: "atan2f",
      header: "<math.h>".}
  proc arctan2*(y, x: float64): float64 {.importc: "atan2", header: "<math.h>".}
    ## Calculate the arc tangent of ``y`` / ``x``.
    ##
    ## It produces correct results even when the resulting angle is near
    ## pi/2 or -pi/2 (``x`` near 0).
    ##
    ## See also:
    ## * `arcsin proc <#arcsin,float64>`_
    ## * `arccos proc <#arccos,float64>`_
    ## * `arctan proc <#arctan,float64>`_
    ## * `tan proc <#tan,float64>`_
    ##
    ## .. code-block:: nim
    ##  echo arctan2(1.0, 0.0) ## 1.570796326794897
    ##  echo radToDeg(arctan2(1.0, 0.0)) ## 90.0
  proc arcsinh*(x: float32): float32 {.importc: "asinhf", header: "<math.h>".}
  proc arcsinh*(x: float64): float64 {.importc: "asinh", header: "<math.h>".}
    ## Computes the inverse hyperbolic sine of ``x``.
  proc arccosh*(x: float32): float32 {.importc: "acoshf", header: "<math.h>".}
  proc arccosh*(x: float64): float64 {.importc: "acosh", header: "<math.h>".}
    ## Computes the inverse hyperbolic cosine of ``x``.
  proc arctanh*(x: float32): float32 {.importc: "atanhf", header: "<math.h>".}
  proc arctanh*(x: float64): float64 {.importc: "atanh", header: "<math.h>".}
    ## Computes the inverse hyperbolic tangent of ``x``.

else: # JS
  proc log10*(x: float32): float32 {.importc: "Math.log10", nodecl.}
  proc log10*(x: float64): float64 {.importc: "Math.log10", nodecl.}
  proc log2*(x: float32): float32 {.importc: "Math.log2", nodecl.}
  proc log2*(x: float64): float64 {.importc: "Math.log2", nodecl.}
  proc exp*(x: float32): float32 {.importc: "Math.exp", nodecl.}
  proc exp*(x: float64): float64 {.importc: "Math.exp", nodecl.}

  proc sin*[T: float32|float64](x: T): T {.importc: "Math.sin", nodecl.}
  proc cos*[T: float32|float64](x: T): T {.importc: "Math.cos", nodecl.}
  proc tan*[T: float32|float64](x: T): T {.importc: "Math.tan", nodecl.}

  proc sinh*[T: float32|float64](x: T): T {.importc: "Math.sinh", nodecl.}
  proc cosh*[T: float32|float64](x: T): T {.importc: "Math.cosh", nodecl.}
  proc tanh*[T: float32|float64](x: T): T {.importc: "Math.tanh", nodecl.}

  proc arcsin*[T: float32|float64](x: T): T {.importc: "Math.asin", nodecl.}
  proc arccos*[T: float32|float64](x: T): T {.importc: "Math.acos", nodecl.}
  proc arctan*[T: float32|float64](x: T): T {.importc: "Math.atan", nodecl.}
  proc arctan2*[T: float32|float64](y, x: T): T {.importc: "Math.atan2", nodecl.}

  proc arcsinh*[T: float32|float64](x: T): T {.importc: "Math.asinh", nodecl.}
  proc arccosh*[T: float32|float64](x: T): T {.importc: "Math.acosh", nodecl.}
  proc arctanh*[T: float32|float64](x: T): T {.importc: "Math.atanh", nodecl.}

proc cot*[T: float32|float64](x: T): T = 1.0 / tan(x)
  ## Computes the cotangent of ``x`` (1 / tan(x)).
proc sec*[T: float32|float64](x: T): T = 1.0 / cos(x)
  ## Computes the secant of ``x`` (1 / cos(x)).
proc csc*[T: float32|float64](x: T): T = 1.0 / sin(x)
  ## Computes the cosecant of ``x`` (1 / sin(x)).

proc coth*[T: float32|float64](x: T): T = 1.0 / tanh(x)
  ## Computes the hyperbolic cotangent of ``x`` (1 / tanh(x)).
proc sech*[T: float32|float64](x: T): T = 1.0 / cosh(x)
  ## Computes the hyperbolic secant of ``x`` (1 / cosh(x)).
proc csch*[T: float32|float64](x: T): T = 1.0 / sinh(x)
  ## Computes the hyperbolic cosecant of ``x`` (1 / sinh(x)).

proc arccot*[T: float32|float64](x: T): T = arctan(1.0 / x)
  ## Computes the inverse cotangent of ``x``.
proc arcsec*[T: float32|float64](x: T): T = arccos(1.0 / x)
  ## Computes the inverse secant of ``x``.
proc arccsc*[T: float32|float64](x: T): T = arcsin(1.0 / x)
  ## Computes the inverse cosecant of ``x``.

proc arccoth*[T: float32|float64](x: T): T = arctanh(1.0 / x)
  ## Computes the inverse hyperbolic cotangent of ``x``.
proc arcsech*[T: float32|float64](x: T): T = arccosh(1.0 / x)
  ## Computes the inverse hyperbolic secant of ``x``.
proc arccsch*[T: float32|float64](x: T): T = arcsinh(1.0 / x)
  ## Computes the inverse hyperbolic cosecant of ``x``.

const windowsCC89 = defined(windows) and defined(bcc)

when not defined(js): # C
  proc hypot*(x, y: float32): float32 {.importc: "hypotf", header: "<math.h>".}
  proc hypot*(x, y: float64): float64 {.importc: "hypot", header: "<math.h>".}
    ## Computes the hypotenuse of a right-angle triangle with ``x`` and
    ## ``y`` as its base and height. Equivalent to ``sqrt(x*x + y*y)``.
    ##
    ## .. code-block:: nim
    ##  echo hypot(4.0, 3.0) ## 5.0
  proc pow*(x, y: float32): float32 {.importc: "powf", header: "<math.h>".}
  proc pow*(x, y: float64): float64 {.importc: "pow", header: "<math.h>".}
    ## Computes x to power raised of y.
    ##
    ## To compute power between integers (e.g. 2^6), use `^ proc<#^,T,Natural>`_.
    ##
    ## See also:
    ## * `^ proc<#^,T,Natural>`_
    ## * `sqrt proc <#sqrt,float64>`_
    ## * `cbrt proc <#cbrt,float64>`_
    ##
    ## .. code-block:: nim
    ##  echo pow(100, 1.5)  ## 1000.0
    ##  echo pow(16.0, 0.5) ## 4.0

  # TODO: add C89 version on windows
  when not windowsCC89:
    proc erf*(x: float32): float32 {.importc: "erff", header: "<math.h>".}
    proc erf*(x: float64): float64 {.importc: "erf", header: "<math.h>".}
      ## Computes the `error function <https://en.wikipedia.org/wiki/Error_function>`_ for ``x``.
      ##
      ## Note: Not available for JS backend.
    proc erfc*(x: float32): float32 {.importc: "erfcf", header: "<math.h>".}
    proc erfc*(x: float64): float64 {.importc: "erfc", header: "<math.h>".}
      ## Computes the `complementary error function <https://en.wikipedia.org/wiki/Error_function#Complementary_error_function>`_ for ``x``.
      ##
      ## Note: Not available for JS backend.
    proc gamma*(x: float32): float32 {.importc: "tgammaf", header: "<math.h>".}
    proc gamma*(x: float64): float64 {.importc: "tgamma", header: "<math.h>".}
      ## Computes the the `gamma function <https://en.wikipedia.org/wiki/Gamma_function>`_ for ``x``.
      ##
      ## Note: Not available for JS backend.
      ##
      ## See also:
      ## * `lgamma proc <#lgamma,float64>`_ for a natural log of gamma function
      ##
      ## .. code-block:: Nim
      ##  echo gamma(1.0)  # 1.0
      ##  echo gamma(4.0)  # 6.0
      ##  echo gamma(11.0) # 3628800.0
      ##  echo gamma(-1.0) # nan
    proc lgamma*(x: float32): float32 {.importc: "lgammaf", header: "<math.h>".}
    proc lgamma*(x: float64): float64 {.importc: "lgamma", header: "<math.h>".}
      ## Computes the natural log of the gamma function for ``x``.
      ##
      ## Note: Not available for JS backend.
      ##
      ## See also:
      ## * `gamma proc <#gamma,float64>`_ for gamma function
      ##
      ## .. code-block:: Nim
      ##  echo lgamma(1.0)  # 1.0
      ##  echo lgamma(4.0)  # 1.791759469228055
      ##  echo lgamma(11.0) # 15.10441257307552
      ##  echo lgamma(-1.0) # inf

  proc floor*(x: float32): float32 {.importc: "floorf", header: "<math.h>".}
  proc floor*(x: float64): float64 {.importc: "floor", header: "<math.h>".}
    ## Computes the floor function (i.e., the largest integer not greater than ``x``).
    ##
    ## See also:
    ## * `ceil proc <#ceil,float64>`_
    ## * `round proc <#round,float64>`_
    ## * `trunc proc <#trunc,float64>`_
    ##
    ## .. code-block:: nim
    ##  echo floor(2.1)  ## 2.0
    ##  echo floor(2.9)  ## 2.0
    ##  echo floor(-3.5) ## -4.0

  proc ceil*(x: float32): float32 {.importc: "ceilf", header: "<math.h>".}
  proc ceil*(x: float64): float64 {.importc: "ceil", header: "<math.h>".}
    ## Computes the ceiling function (i.e., the smallest integer not smaller
    ## than ``x``).
    ##
    ## See also:
    ## * `floor proc <#floor,float64>`_
    ## * `round proc <#round,float64>`_
    ## * `trunc proc <#trunc,float64>`_
    ##
    ## .. code-block:: nim
    ##  echo ceil(2.1)  ## 3.0
    ##  echo ceil(2.9)  ## 3.0
    ##  echo ceil(-2.1) ## -2.0

  when windowsCC89:
    # MSVC 2010 don't have trunc/truncf
    # this implementation was inspired by Go-lang Math.Trunc
    proc truncImpl(f: float64): float64 =
      const
        mask: uint64 = 0x7FF
        shift: uint64 = 64 - 12
        bias: uint64 = 0x3FF

      if f < 1:
        if f < 0: return -truncImpl(-f)
        elif f == 0: return f # Return -0 when f == -0
        else: return 0

      var x = cast[uint64](f)
      let e = (x shr shift) and mask - bias

      # Keep the top 12+e bits, the integer part; clear the rest.
      if e < 64-12:
        x = x and (not (1'u64 shl (64'u64-12'u64-e) - 1'u64))

      result = cast[float64](x)

    proc truncImpl(f: float32): float32 =
      const
        mask: uint32 = 0xFF
        shift: uint32 = 32 - 9
        bias: uint32 = 0x7F

      if f < 1:
        if f < 0: return -truncImpl(-f)
        elif f == 0: return f # Return -0 when f == -0
        else: return 0

      var x = cast[uint32](f)
      let e = (x shr shift) and mask - bias

      # Keep the top 9+e bits, the integer part; clear the rest.
      if e < 32-9:
        x = x and (not (1'u32 shl (32'u32-9'u32-e) - 1'u32))

      result = cast[float32](x)

    proc trunc*(x: float64): float64 =
      if classify(x) in {fcZero, fcNegZero, fcNan, fcInf, fcNegInf}: return x
      result = truncImpl(x)

    proc trunc*(x: float32): float32 =
      if classify(x) in {fcZero, fcNegZero, fcNan, fcInf, fcNegInf}: return x
      result = truncImpl(x)

    proc round*[T: float32|float64](x: T): T =
      ## Windows compilers prior to MSVC 2012 do not implement 'round',
      ## 'roundl' or 'roundf'.
      result = if x < 0.0: ceil(x - T(0.5)) else: floor(x + T(0.5))
  else:
    proc round*(x: float32): float32 {.importc: "roundf", header: "<math.h>".}
    proc round*(x: float64): float64 {.importc: "round", header: "<math.h>".}
      ## Rounds a float to zero decimal places.
      ##
      ## Used internally by the `round proc <#round,T,int>`_
      ## when the specified number of places is 0.
      ##
      ## See also:
      ## * `round proc <#round,T,int>`_ for rounding to the specific
      ##   number of decimal places
      ## * `floor proc <#floor,float64>`_
      ## * `ceil proc <#ceil,float64>`_
      ## * `trunc proc <#trunc,float64>`_
      ##
      ## .. code-block:: nim
      ##   echo round(3.4) ## 3.0
      ##   echo round(3.5) ## 4.0
      ##   echo round(4.5) ## 5.0

    proc trunc*(x: float32): float32 {.importc: "truncf", header: "<math.h>".}
    proc trunc*(x: float64): float64 {.importc: "trunc", header: "<math.h>".}
      ## Truncates ``x`` to the decimal point.
      ##
      ## See also:
      ## * `floor proc <#floor,float64>`_
      ## * `ceil proc <#ceil,float64>`_
      ## * `round proc <#round,float64>`_
      ##
      ## .. code-block:: nim
      ##  echo trunc(PI) # 3.0
      ##  echo trunc(-1.85) # -1.0

  proc `mod`*(x, y: float32): float32 {.importc: "fmodf", header: "<math.h>".}
  proc `mod`*(x, y: float64): float64 {.importc: "fmod", header: "<math.h>".}
    ## Computes the modulo operation for float values (the remainder of ``x`` divided by ``y``).
    ##
    ## See also:
    ## * `floorMod proc <#floorMod,T,T>`_ for Python-like (% operator) behavior
    ##
    ## .. code-block:: nim
    ##  ( 6.5 mod  2.5) ==  1.5
    ##  (-6.5 mod  2.5) == -1.5
    ##  ( 6.5 mod -2.5) ==  1.5
    ##  (-6.5 mod -2.5) == -1.5

else: # JS
  proc hypot*(x, y: float32): float32 {.importc: "Math.hypot", varargs, nodecl.}
  proc hypot*(x, y: float64): float64 {.importc: "Math.hypot", varargs, nodecl.}
  proc pow*(x, y: float32): float32 {.importc: "Math.pow", nodecl.}
  proc pow*(x, y: float64): float64 {.importc: "Math.pow", nodecl.}
  proc floor*(x: float32): float32 {.importc: "Math.floor", nodecl.}
  proc floor*(x: float64): float64 {.importc: "Math.floor", nodecl.}
  proc ceil*(x: float32): float32 {.importc: "Math.ceil", nodecl.}
  proc ceil*(x: float64): float64 {.importc: "Math.ceil", nodecl.}
  proc round*(x: float): float {.importc: "Math.round", nodecl.}
  proc trunc*(x: float32): float32 {.importc: "Math.trunc", nodecl.}
  proc trunc*(x: float64): float64 {.importc: "Math.trunc", nodecl.}

  proc `mod`*(x, y: float32): float32 {.importcpp: "# % #".}
  proc `mod`*(x, y: float64): float64 {.importcpp: "# % #".}
    ## Computes the modulo operation for float values (the remainder of ``x`` divided by ``y``).
    ##
    ## .. code-block:: nim
    ##  ( 6.5 mod  2.5) ==  1.5
    ##  (-6.5 mod  2.5) == -1.5
    ##  ( 6.5 mod -2.5) ==  1.5
    ##  (-6.5 mod -2.5) == -1.5

proc round*[T: float32|float64](x: T, places: int): T {.
    deprecated: "use strformat module instead".} =
  ## Decimal rounding on a binary floating point number.
  ##
  ## This function is NOT reliable. Floating point numbers cannot hold
  ## non integer decimals precisely. If ``places`` is 0 (or omitted),
  ## round to the nearest integral value following normal mathematical
  ## rounding rules (e.g.  ``round(54.5) -> 55.0``). If ``places`` is
  ## greater than 0, round to the given number of decimal places,
  ## e.g. ``round(54.346, 2) -> 54.350000000000001421…``. If ``places`` is negative, round
  ## to the left of the decimal place, e.g. ``round(537.345, -1) ->
  ## 540.0``
  ##
  ## .. code-block:: Nim
  ##  echo round(PI, 2) ## 3.14
  ##  echo round(PI, 4) ## 3.1416
  if places == 0:
    result = round(x)
  else:
    var mult = pow(10.0, places.T)
    result = round(x*mult)/mult

proc floorDiv*[T: SomeInteger](x, y: T): T =
  ## Floor division is conceptually defined as ``floor(x / y)``.
  ##
  ## This is different from the `system.div <system.html#div,int,int>`_
  ## operator, which is defined as ``trunc(x / y)``.
  ## That is, ``div`` rounds towards ``0`` and ``floorDiv`` rounds down.
  ##
  ## See also:
  ## * `system.div proc <system.html#div,int,int>`_ for integer division
  ## * `floorMod proc <#floorMod,T,T>`_ for Python-like (% operator) behavior
  ##
  ## .. code-block:: nim
  ##  echo floorDiv( 13,  3) #  4
  ##  echo floorDiv(-13,  3) # -5
  ##  echo floorDiv( 13, -3) # -5
  ##  echo floorDiv(-13, -3) #  4
  result = x div y
  let r = x mod y
  if (r > 0 and y < 0) or (r < 0 and y > 0): result.dec 1

proc floorMod*[T: SomeNumber](x, y: T): T =
  ## Floor modulus is conceptually defined as ``x - (floorDiv(x, y) * y)``.
  ##
  ## This proc behaves the same as the ``%`` operator in Python.
  ##
  ## See also:
  ## * `mod proc <#mod,float64,float64>`_
  ## * `floorDiv proc <#floorDiv,T,T>`_
  ##
  ## .. code-block:: nim
  ##  echo floorMod( 13,  3) #  1
  ##  echo floorMod(-13,  3) #  2
  ##  echo floorMod( 13, -3) # -2
  ##  echo floorMod(-13, -3) # -1
  result = x mod y
  if (result > 0 and y < 0) or (result < 0 and y > 0): result += y

when not defined(js):
  proc c_frexp*(x: float32, exponent: var int32): float32 {.
    importc: "frexp", header: "<math.h>".}
  proc c_frexp*(x: float64, exponent: var int32): float64 {.
    importc: "frexp", header: "<math.h>".}
  proc frexp*[T, U](x: T, exponent: var U): T =
    ## Split a number into mantissa and exponent.
    ##
    ## ``frexp`` calculates the mantissa m (a float greater than or equal to 0.5
    ## and less than 1) and the integer value n such that ``x`` (the original
    ## float value) equals ``m * 2**n``. frexp stores n in `exponent` and returns
    ## m.
    ##
    ## .. code-block:: nim
    ##  var x: int
    ##  echo frexp(5.0, x) # 0.625
    ##  echo x # 3
    var exp: int32
    result = c_frexp(x, exp)
    exponent = exp

  when windowsCC89:
    # taken from Go-lang Math.Log2
    const ln2 = 0.693147180559945309417232121458176568075500134360255254120680009
    template log2Impl[T](x: T): T =
      var exp: int32
      var frac = frexp(x, exp)
      # Make sure exact powers of two give an exact answer.
      # Don't depend on Log(0.5)*(1/Ln2)+exp being exactly exp-1.
      if frac == 0.5: return T(exp - 1)
      log10(frac)*(1/ln2) + T(exp)

    proc log2*(x: float32): float32 = log2Impl(x)
    proc log2*(x: float64): float64 = log2Impl(x)
      ## Log2 returns the binary logarithm of x.
      ## The special cases are the same as for Log.

  else:
    proc log2*(x: float32): float32 {.importc: "log2f", header: "<math.h>".}
    proc log2*(x: float64): float64 {.importc: "log2", header: "<math.h>".}
      ## Computes the binary logarithm (base 2) of ``x``.
      ##
      ## See also:
      ## * `log proc <#log,T,T>`_
      ## * `log10 proc <#log10,float64>`_
      ## * `ln proc <#ln,float64>`_
      ## * `exp proc <#exp,float64>`_
      ##
      ## .. code-block:: Nim
      ##  echo log2(8.0)  # 3.0
      ##  echo log2(1.0)  # 0.0
      ##  echo log2(0.0)  # -inf
      ##  echo log2(-2.0) # nan

else:
  proc frexp*[T: float32|float64](x: T, exponent: var int): T =
    if x == 0.0:
      exponent = 0
      result = 0.0
    elif x < 0.0:
      result = -frexp(-x, exponent)
    else:
      var ex = trunc(log2(x))
      exponent = int(ex)
      result = x / pow(2.0, ex)
      if abs(result) >= 1:
        inc(exponent)
        result = result / 2
      if exponent == 1024 and result == 0.0:
        result = 0.99999999999999988898

proc splitDecimal*[T: float32|float64](x: T): tuple[intpart: T, floatpart: T] =
  ## Breaks ``x`` into an integer and a fractional part.
  ##
  ## Returns a tuple containing ``intpart`` and ``floatpart`` representing
  ## the integer part and the fractional part respectively.
  ##
  ## Both parts have the same sign as ``x``.  Analogous to the ``modf``
  ## function in C.
  ##
  ## .. code-block:: nim
  ##  echo splitDecimal(5.25)  # (intpart: 5.0, floatpart: 0.25)
  ##  echo splitDecimal(-2.73) # (intpart: -2.0, floatpart: -0.73)
  var
    absolute: T
  absolute = abs(x)
  result.intpart = floor(absolute)
  result.floatpart = absolute - result.intpart
  if x < 0:
    result.intpart = -result.intpart
    result.floatpart = -result.floatpart

{.pop.}

proc degToRad*[T: float32|float64](d: T): T {.inline.} =
  ## Convert from degrees to radians.
  ##
  ## See also:
  ## * `radToDeg proc <#radToDeg,T>`_
  ##
  ## .. code-block:: nim
  ##  echo degToRad(180.0) # 3.141592653589793
  result = T(d) * RadPerDeg

proc radToDeg*[T: float32|float64](d: T): T {.inline.} =
  ## Convert from radians to degrees.
  ##
  ## See also:
  ## * `degToRad proc <#degToRad,T>`_
  ##
  ## .. code-block:: nim
  ##  echo degToRad(2 * PI) # 360.0
  result = T(d) / RadPerDeg

proc sgn*[T: SomeNumber](x: T): int {.inline.} =
  ## Sign function.
  ##
  ## Returns:
  ## * `-1` for negative numbers and ``NegInf``,
  ## * `1` for positive numbers and ``Inf``,
  ## * `0` for positive zero, negative zero and ``NaN``
  ##
  ## .. code-block:: nim
  ##  echo sgn(5)    # 1
  ##  echo sgn(0)    # 0
  ##  echo sgn(-4.1) # -1
  ord(T(0) < x) - ord(x < T(0))

{.pop.}
{.pop.}

proc `^`*[T: SomeNumber](x: T, y: Natural): T =
  ## Computes ``x`` to the power ``y``.
  ##
  ## Exponent ``y`` must be non-negative, use
  ## `pow proc <#pow,float64,float64>`_ for negative exponents.
  ##
  ## See also:
  ## * `pow proc <#pow,float64,float64>`_ for negative exponent or
  ##   floats
  ## * `sqrt proc <#sqrt,float64>`_
  ## * `cbrt proc <#cbrt,float64>`_
  ##
  runnableExamples:
    assert -3.0^0 == 1.0
    assert -3^1 == -3
    assert -3^2 == 9
    assert -3.0^3 == -27.0
    assert -3.0^4 == 81.0

  case y
  of 0: result = 1
  of 1: result = x
  of 2: result = x * x
  of 3: result = x * x * x
  else:
    var (x, y) = (x, y)
    result = 1
    while true:
      if (y and 1) != 0:
        result *= x
      y = y shr 1
      if y == 0:
        break
      x *= x

proc gcd*[T](x, y: T): T =
  ## Computes the greatest common (positive) divisor of ``x`` and ``y``.
  ##
  ## Note that for floats, the result cannot always be interpreted as
  ## "greatest decimal `z` such that ``z*N == x and z*M == y``
  ## where N and M are positive integers."
  ##
  ## See also:
  ## * `gcd proc <#gcd,SomeInteger,SomeInteger>`_ for integer version
  ## * `lcm proc <#lcm,T,T>`_
  runnableExamples:
    doAssert gcd(13.5, 9.0) == 4.5
  var (x, y) = (x, y)
  while y != 0:
    x = x mod y
    swap x, y
  abs x

proc gcd*(x, y: SomeInteger): SomeInteger =
  ## Computes the greatest common (positive) divisor of ``x`` and ``y``,
  ## using binary GCD (aka Stein's) algorithm.
  ##
  ## See also:
  ## * `gcd proc <#gcd,T,T>`_ for floats version
  ## * `lcm proc <#lcm,T,T>`_
  runnableExamples:
    doAssert gcd(12, 8) == 4
    doAssert gcd(17, 63) == 1
  when x is SomeSignedInt:
    var x = abs(x)
  else:
    var x = x
  when y is SomeSignedInt:
    var y = abs(y)
  else:
    var y = y

  if x == 0:
    return y
  if y == 0:
    return x

  let shift = countTrailingZeroBits(x or y)
  y = y shr countTrailingZeroBits(y)
  while x != 0:
    x = x shr countTrailingZeroBits(x)
    if y > x:
      swap y, x
    x -= y
  y shl shift

proc gcd*[T](x: openArray[T]): T {.since: (1, 1).} =
  ## Computes the greatest common (positive) divisor of the elements of ``x``.
  ##
  ## See also:
  ## * `gcd proc <#gcd,T,T>`_ for integer version
  runnableExamples:
    doAssert gcd(@[13.5, 9.0]) == 4.5
  result = x[0]
  var i = 1
  while i < x.len:
    result = gcd(result, x[i])
    inc(i)

proc lcm*[T](x, y: T): T =
  ## Computes the least common multiple of ``x`` and ``y``.
  ##
  ## See also:
  ## * `gcd proc <#gcd,T,T>`_
  runnableExamples:
    doAssert lcm(24, 30) == 120
    doAssert lcm(13, 39) == 39
  x div gcd(x, y) * y

proc lcm*[T](x: openArray[T]): T {.since: (1, 1).} =
  ## Computes the least common multiple of the elements of ``x``.
  ##
  ## See also:
  ## * `gcd proc <#gcd,T,T>`_ for integer version
  runnableExamples:
    doAssert lcm(@[24, 30]) == 120
  result = x[0]
  var i = 1
  while i < x.len:
    result = lcm(result, x[i])
    inc(i)

when isMainModule and not defined(js) and not windowsCC89:
  # Check for no side effect annotation
  proc mySqrt(num: float): float {.noSideEffect.} =
    return sqrt(num)

  # check gamma function
  assert(gamma(5.0) == 24.0) # 4!
  assert(lgamma(1.0) == 0.0) # ln(1.0) == 0.0
  assert(erf(6.0) > erf(5.0))
  assert(erfc(6.0) < erfc(5.0))

when isMainModule:
  # Function for approximate comparison of floats
  proc `==~`(x, y: float): bool = (abs(x-y) < 1e-9)

  block: # prod
    doAssert prod([1, 2, 3, 4]) == 24
    doAssert prod([1.5, 3.4]) == 5.1
    let x: seq[float] = @[]
    doAssert prod(x) == 1.0

  block: # round() tests
    # Round to 0 decimal places
    doAssert round(54.652) ==~ 55.0
    doAssert round(54.352) ==~ 54.0
    doAssert round(-54.652) ==~ -55.0
    doAssert round(-54.352) ==~ -54.0
    doAssert round(0.0) ==~ 0.0

  block: # splitDecimal() tests
    doAssert splitDecimal(54.674).intpart ==~ 54.0
    doAssert splitDecimal(54.674).floatpart ==~ 0.674
    doAssert splitDecimal(-693.4356).intpart ==~ -693.0
    doAssert splitDecimal(-693.4356).floatpart ==~ -0.4356
    doAssert splitDecimal(0.0).intpart ==~ 0.0
    doAssert splitDecimal(0.0).floatpart ==~ 0.0

  block: # trunc tests for vcc
    doAssert(trunc(-1.1) == -1)
    doAssert(trunc(1.1) == 1)
    doAssert(trunc(-0.1) == -0)
    doAssert(trunc(0.1) == 0)

    #special case
    doAssert(classify(trunc(1e1000000)) == fcInf)
    doAssert(classify(trunc(-1e1000000)) == fcNegInf)
    doAssert(classify(trunc(0.0/0.0)) == fcNan)
    doAssert(classify(trunc(0.0)) == fcZero)

    #trick the compiler to produce signed zero
    let
      f_neg_one = -1.0
      f_zero = 0.0
      f_nan = f_zero / f_zero

    doAssert(classify(trunc(f_neg_one*f_zero)) == fcNegZero)

    doAssert(trunc(-1.1'f32) == -1)
    doAssert(trunc(1.1'f32) == 1)
    doAssert(trunc(-0.1'f32) == -0)
    doAssert(trunc(0.1'f32) == 0)
    doAssert(classify(trunc(1e1000000'f32)) == fcInf)
    doAssert(classify(trunc(-1e1000000'f32)) == fcNegInf)
    doAssert(classify(trunc(f_nan.float32)) == fcNan)
    doAssert(classify(trunc(0.0'f32)) == fcZero)

  block: # sgn() tests
    assert sgn(1'i8) == 1
    assert sgn(1'i16) == 1
    assert sgn(1'i32) == 1
    assert sgn(1'i64) == 1
    assert sgn(1'u8) == 1
    assert sgn(1'u16) == 1
    assert sgn(1'u32) == 1
    assert sgn(1'u64) == 1
    assert sgn(-12342.8844'f32) == -1
    assert sgn(123.9834'f64) == 1
    assert sgn(0'i32) == 0
    assert sgn(0'f32) == 0
    assert sgn(NegInf) == -1
    assert sgn(Inf) == 1
    assert sgn(NaN) == 0

  block: # fac() tests
    try:
      discard fac(-1)
    except AssertionDefect:
      discard

    doAssert fac(0) == 1
    doAssert fac(1) == 1
    doAssert fac(2) == 2
    doAssert fac(3) == 6
    doAssert fac(4) == 24

  block: # floorMod/floorDiv
    doAssert floorDiv(8, 3) == 2
    doAssert floorMod(8, 3) == 2

    doAssert floorDiv(8, -3) == -3
    doAssert floorMod(8, -3) == -1

    doAssert floorDiv(-8, 3) == -3
    doAssert floorMod(-8, 3) == 1

    doAssert floorDiv(-8, -3) == 2
    doAssert floorMod(-8, -3) == -2

    doAssert floorMod(8.0, -3.0) ==~ -1.0
    doAssert floorMod(-8.5, 3.0) ==~ 0.5

  block: # log
    doAssert log(4.0, 3.0) ==~ ln(4.0) / ln(3.0)
    doAssert log2(8.0'f64) == 3.0'f64
    doAssert log2(4.0'f64) == 2.0'f64
    doAssert log2(2.0'f64) == 1.0'f64
    doAssert log2(1.0'f64) == 0.0'f64
    doAssert classify(log2(0.0'f64)) == fcNegInf

    doAssert log2(8.0'f32) == 3.0'f32
    doAssert log2(4.0'f32) == 2.0'f32
    doAssert log2(2.0'f32) == 1.0'f32
    doAssert log2(1.0'f32) == 0.0'f32
    doAssert classify(log2(0.0'f32)) == fcNegInf
