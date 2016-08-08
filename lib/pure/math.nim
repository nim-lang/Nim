#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

##   Constructive mathematics is naturally typed. -- Simon Thompson
##
## Basic math routines for Nim.
## This module is available for the `JavaScript target
## <backends.html#the-javascript-target>`_.
##
## Note that the trigonometric functions naturally operate on radians.
## The helper functions `degToRad` and `radToDeg` provide conversion
## between radians and degrees.

include "system/inclrtl"
{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!

proc binom*(n, k: int): int {.noSideEffect.} =
  ## Computes the binomial coefficient
  if k <= 0: return 1
  if 2*k > n: return binom(n, n-k)
  result = n
  for i in countup(2, k):
    result = (result * (n + 1 - i)) div i

proc fac*(n: int): int {.noSideEffect.} =
  ## Computes the faculty/factorial function.
  result = 1
  for i in countup(2, n):
    result = result * i

{.push checks:off, line_dir:off, stack_trace:off.}

when defined(Posix) and not defined(haiku):
  {.passl: "-lm".}

const
  PI* = 3.1415926535897932384626433 ## the circle constant PI (Ludolph's number)
  TAU* = 2.0 * PI ## the circle constant TAU (= 2 * PI)
  E* = 2.71828182845904523536028747 ## Euler's number

  MaxFloat64Precision* = 16 ## maximum number of meaningful digits
                            ## after the decimal point for Nim's
                            ## ``float64`` type.
  MaxFloat32Precision* = 8  ## maximum number of meaningful digits
                            ## after the decimal point for Nim's
                            ## ``float32`` type.
  MaxFloatPrecision* = MaxFloat64Precision ## maximum number of
                                           ## meaningful digits
                                           ## after the decimal point
                                           ## for Nim's ``float`` type.
  RadPerDeg = PI / 180.0 ## number of radians per degree

type
  FloatClass* = enum ## describes the class a floating point value belongs to.
                     ## This is the type that is returned by `classify`.
    fcNormal,    ## value is an ordinary nonzero floating point value
    fcSubnormal, ## value is a subnormal (a very small) floating point value
    fcZero,      ## value is zero
    fcNegZero,   ## value is the negative zero
    fcNan,       ## value is Not-A-Number (NAN)
    fcInf,       ## value is positive infinity
    fcNegInf     ## value is negative infinity

proc classify*(x: float): FloatClass =
  ## Classifies a floating point value. Returns `x`'s class as specified by
  ## `FloatClass`.

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
  return fcNormal
  # XXX: fcSubnormal is not detected!

proc isPowerOfTwo*(x: int): bool {.noSideEffect.} =
  ## Returns true, if `x` is a power of two, false otherwise.
  ## Zero and negative numbers are not a power of two.
  return (x > 0) and ((x and (x - 1)) == 0)

proc nextPowerOfTwo*(x: int): int {.noSideEffect.} =
  ## Returns `x` rounded up to the nearest power of two.
  ## Zero and negative numbers get rounded up to 1.
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
  result += 1 + ord(x<=0)

proc countBits32*(n: int32): int {.noSideEffect.} =
  ## Counts the set bits in `n`.
  var v = n
  v = v -% ((v shr 1'i32) and 0x55555555'i32)
  v = (v and 0x33333333'i32) +% ((v shr 2'i32) and 0x33333333'i32)
  result = ((v +% (v shr 4'i32) and 0xF0F0F0F'i32) *% 0x1010101'i32) shr 24'i32

proc sum*[T](x: openArray[T]): T {.noSideEffect.} =
  ## Computes the sum of the elements in `x`.
  ## If `x` is empty, 0 is returned.
  for i in items(x): result = result + i

{.push noSideEffect.}
when not defined(JS):
  proc sqrt*(x: float32): float32 {.importc: "sqrtf", header: "<math.h>".}
  proc sqrt*(x: float64): float64 {.importc: "sqrt", header: "<math.h>".}
    ## Computes the square root of `x`.
  proc cbrt*(x: float32): float32 {.importc: "cbrtf", header: "<math.h>".}
  proc cbrt*(x: float64): float64 {.importc: "cbrt", header: "<math.h>".}
    ## Computes the cubic root of `x`

  proc ln*(x: float32): float32 {.importc: "logf", header: "<math.h>".}
  proc ln*(x: float64): float64 {.importc: "log", header: "<math.h>".}
    ## Computes the natural log of `x`
  proc log10*(x: float32): float32 {.importc: "log10f", header: "<math.h>".}
  proc log10*(x: float64): float64 {.importc: "log10", header: "<math.h>".}
    ## Computes the common logarithm (base 10) of `x`
  proc log2*[T: float32|float64](x: T): T = return ln(x) / ln(2.0)
    ## Computes the binary logarithm (base 2) of `x`
  proc exp*(x: float32): float32 {.importc: "expf", header: "<math.h>".}
  proc exp*(x: float64): float64 {.importc: "exp", header: "<math.h>".}
    ## Computes the exponential function of `x` (pow(E, x))

  proc arccos*(x: float32): float32 {.importc: "acosf", header: "<math.h>".}
  proc arccos*(x: float64): float64 {.importc: "acos", header: "<math.h>".}
    ## Computes the arc cosine of `x`
  proc arcsin*(x: float32): float32 {.importc: "asinf", header: "<math.h>".}
  proc arcsin*(x: float64): float64 {.importc: "asin", header: "<math.h>".}
    ## Computes the arc sine of `x`
  proc arctan*(x: float32): float32 {.importc: "atanf", header: "<math.h>".}
  proc arctan*(x: float64): float64 {.importc: "atan", header: "<math.h>".}
    ## Calculate the arc tangent of `y` / `x`
  proc arctan2*(y, x: float32): float32 {.importc: "atan2f", header: "<math.h>".}
  proc arctan2*(y, x: float64): float64 {.importc: "atan2", header: "<math.h>".}
    ## Calculate the arc tangent of `y` / `x`.
    ## `atan2` returns the arc tangent of `y` / `x`; it produces correct
    ## results even when the resulting angle is near pi/2 or -pi/2
    ## (`x` near 0).

  proc cos*(x: float32): float32 {.importc: "cosf", header: "<math.h>".}
  proc cos*(x: float64): float64 {.importc: "cos", header: "<math.h>".}
    ## Computes the cosine of `x`

  proc cosh*(x: float32): float32 {.importc: "coshf", header: "<math.h>".}
  proc cosh*(x: float64): float64 {.importc: "cosh", header: "<math.h>".}
    ## Computes the hyperbolic cosine of `x`

  proc hypot*(x, y: float32): float32 {.importc: "hypotf", header: "<math.h>".}
  proc hypot*(x, y: float64): float64 {.importc: "hypot", header: "<math.h>".}
    ## Computes the hypotenuse of a right-angle triangle with `x` and
    ## `y` as its base and height. Equivalent to ``sqrt(x*x + y*y)``.

  proc sinh*(x: float32): float32 {.importc: "sinhf", header: "<math.h>".}
  proc sinh*(x: float64): float64 {.importc: "sinh", header: "<math.h>".}
    ## Computes the hyperbolic sine of `x`
  proc sin*(x: float32): float32 {.importc: "sinf", header: "<math.h>".}
  proc sin*(x: float64): float64 {.importc: "sin", header: "<math.h>".}
    ## Computes the sine of `x`

  proc tan*(x: float32): float32 {.importc: "tanf", header: "<math.h>".}
  proc tan*(x: float64): float64 {.importc: "tan", header: "<math.h>".}
    ## Computes the tangent of `x`
  proc tanh*(x: float32): float32 {.importc: "tanhf", header: "<math.h>".}
  proc tanh*(x: float64): float64 {.importc: "tanh", header: "<math.h>".}
    ## Computes the hyperbolic tangent of `x`

  proc pow*(x, y: float32): float32 {.importc: "powf", header: "<math.h>".}
  proc pow*(x, y: float64): float64 {.importc: "pow", header: "<math.h>".}
    ## computes x to power raised of y.

  proc erf*(x: float32): float32 {.importc: "erff", header: "<math.h>".}
  proc erf*(x: float64): float64 {.importc: "erf", header: "<math.h>".}
    ## The error function
  proc erfc*(x: float32): float32 {.importc: "erfcf", header: "<math.h>".}
  proc erfc*(x: float64): float64 {.importc: "erfc", header: "<math.h>".}
    ## The complementary error function

  proc lgamma*(x: float32): float32 {.importc: "lgammaf", header: "<math.h>".}
  proc lgamma*(x: float64): float64 {.importc: "lgamma", header: "<math.h>".}
    ## Natural log of the gamma function
  proc tgamma*(x: float32): float32 {.importc: "tgammaf", header: "<math.h>".}
  proc tgamma*(x: float64): float64 {.importc: "tgamma", header: "<math.h>".}
    ## The gamma function

  proc trunc*(x: float32): float32 {.importc: "truncf", header: "<math.h>".}
  proc trunc*(x: float64): float64 {.importc: "trunc", header: "<math.h>".}
    ## Truncates `x` to the decimal point
    ##
    ## .. code-block:: nim
    ##  echo trunc(PI) # 3.0

  proc floor*(x: float32): float32 {.importc: "floorf", header: "<math.h>".}
  proc floor*(x: float64): float64 {.importc: "floor", header: "<math.h>".}
    ## Computes the floor function (i.e., the largest integer not greater than `x`)
    ##
    ## .. code-block:: nim
    ##  echo floor(-3.5) ## -4.0

  proc ceil*(x: float32): float32 {.importc: "ceilf", header: "<math.h>".}
  proc ceil*(x: float64): float64 {.importc: "ceil", header: "<math.h>".}
    ## Computes the ceiling function (i.e., the smallest integer not less than `x`)
    ##
    ## .. code-block:: nim
    ##  echo ceil(-2.1) ## -2.0

  when defined(windows) and defined(vcc):
    proc round0[T: float32|float64](x: T): T =
      ## Windows compilers prior to MSVC 2012 do not implement 'round',
      ## 'roundl' or 'roundf'.
      result = if x < 0.0: ceil(x - T(0.5)) else: floor(x + T(0.5))
  else:
    proc round0(x: float32): float32 {.importc: "roundf", header: "<math.h>".}
    proc round0(x: float64): float64 {.importc: "round", header: "<math.h>".}
      ## Rounds a float to zero decimal places.  Used internally by the round
      ## function when the specified number of places is 0.

  proc fmod*(x, y: float32): float32 {.importc: "fmodf", header: "<math.h>".}
  proc fmod*(x, y: float64): float64 {.importc: "fmod", header: "<math.h>".}
    ## Computes the remainder of `x` divided by `y`
    ##
    ## .. code-block:: nim
    ##  echo fmod(-2.5, 0.3) ## -0.1

else:
  proc floor*(x: float32): float32 {.importc: "Math.floor", nodecl.}
  proc floor*(x: float64): float64 {.importc: "Math.floor", nodecl.}
  proc ceil*(x: float32): float32 {.importc: "Math.ceil", nodecl.}
  proc ceil*(x: float64): float64 {.importc: "Math.ceil", nodecl.}

  proc sqrt*(x: float32): float32 {.importc: "Math.sqrt", nodecl.}
  proc sqrt*(x: float64): float64 {.importc: "Math.sqrt", nodecl.}
  proc ln*(x: float32): float32 {.importc: "Math.log", nodecl.}
  proc ln*(x: float64): float64 {.importc: "Math.log", nodecl.}
  proc log10*[T: float32|float64](x: T): T = return ln(x) / ln(10.0)
  proc log2*[T: float32|float64](x: T): T = return ln(x) / ln(2.0)

  proc exp*(x: float32): float32 {.importc: "Math.exp", nodecl.}
  proc exp*(x: float64): float64 {.importc: "Math.exp", nodecl.}
  proc round0(x: float): float {.importc: "Math.round", nodecl.}

  proc pow*(x, y: float32): float32 {.importC: "Math.pow", nodecl.}
  proc pow*(x, y: float64): float64 {.importc: "Math.pow", nodecl.}

  proc arccos*(x: float32): float32 {.importc: "Math.acos", nodecl.}
  proc arccos*(x: float64): float64 {.importc: "Math.acos", nodecl.}
  proc arcsin*(x: float32): float32 {.importc: "Math.asin", nodecl.}
  proc arcsin*(x: float64): float64 {.importc: "Math.asin", nodecl.}
  proc arctan*(x: float32): float32 {.importc: "Math.atan", nodecl.}
  proc arctan*(x: float64): float64 {.importc: "Math.atan", nodecl.}
  proc arctan2*(y, x: float32): float32 {.importC: "Math.atan2", nodecl.}
  proc arctan2*(y, x: float64): float64 {.importc: "Math.atan2", nodecl.}

  proc cos*(x: float32): float32 {.importc: "Math.cos", nodecl.}
  proc cos*(x: float64): float64 {.importc: "Math.cos", nodecl.}
  proc cosh*(x: float32): float32 = return (exp(x)+exp(-x))*0.5
  proc cosh*(x: float64): float64 = return (exp(x)+exp(-x))*0.5
  proc hypot*[T: float32|float64](x, y: T): T = return sqrt(x*x + y*y)
  proc sinh*[T: float32|float64](x: T): T = return (exp(x)-exp(-x))*0.5
  proc sin*(x: float32): float32 {.importc: "Math.sin", nodecl.}
  proc sin*(x: float64): float64 {.importc: "Math.sin", nodecl.}
  proc tan*(x: float32): float32 {.importc: "Math.tan", nodecl.}
  proc tan*(x: float64): float64 {.importc: "Math.tan", nodecl.}
  proc tanh*[T: float32|float64](x: T): T =
    var y = exp(2.0*x)
    return (y-1.0)/(y+1.0)

proc round*[T: float32|float64](x: T, places: int = 0): T =
  ## Round a floating point number.
  ##
  ## If `places` is 0 (or omitted), round to the nearest integral value
  ## following normal mathematical rounding rules (e.g. `round(54.5) -> 55.0`).
  ## If `places` is greater than 0, round to the given number of decimal
  ## places, e.g. `round(54.346, 2) -> 54.35`.
  ## If `places` is negative, round to the left of the decimal place, e.g.
  ## `round(537.345, -1) -> 540.0`
  if places == 0:
    result = round0(x)
  else:
    var mult = pow(10.0, places.T)
    result = round0(x*mult)/mult

when not defined(JS):
  proc frexp*(x: float32, exponent: var int): float32 {.
    importc: "frexp", header: "<math.h>".}
  proc frexp*(x: float64, exponent: var int): float64 {.
    importc: "frexp", header: "<math.h>".}
    ## Split a number into mantissa and exponent.
    ## `frexp` calculates the mantissa m (a float greater than or equal to 0.5
    ## and less than 1) and the integer value n such that `x` (the original
    ## float value) equals m * 2**n. frexp stores n in `exponent` and returns
    ## m.
else:
  proc frexp*[T: float32|float64](x: T, exponent: var int): T =
    if x == 0.0:
      exponent = 0
      result = 0.0
    elif x < 0.0:
      result = -frexp(-x, exponent)
    else:
      var ex = floor(log2(x))
      exponent = round(ex)
      result = x / pow(2.0, ex)

proc splitDecimal*[T: float32|float64](x: T): tuple[intpart: T, floatpart: T] =
  ## Breaks `x` into an integral and a fractional part.
  ##
  ## Returns a tuple containing intpart and floatpart representing
  ## the integer part and the fractional part respectively.
  ##
  ## Both parts have the same sign as `x`.  Analogous to the `modf`
  ## function in C.
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
  ## Convert from degrees to radians
  result = T(d) * RadPerDeg

proc radToDeg*[T: float32|float64](d: T): T {.inline.} =
  ## Convert from radians to degrees
  result = T(d) / RadPerDeg

proc `mod`*[T: float32|float64](x, y: T): T =
  ## Computes the modulo operation for float operators. Equivalent
  ## to ``x - y * floor(x/y)``. Note that the remainder will always
  ## have the same sign as the divisor.
  ##
  ## .. code-block:: nim
  ##  echo (4.0 mod -3.1) # -2.2
  result = if y == 0.0: x else: x - y * (x/y).floor

{.pop.}
{.pop.}

proc `^`*[T](x, y: T): T =
  ## Computes ``x`` to the power ``y`. ``x`` must be non-negative, use
  ## `pow <#pow,float,float>` for negative exponents.
  assert y >= T(0)
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
  ## Computes the greatest common divisor of ``x`` and ``y``.
  ## Note that for floats, the result cannot always be interpreted as
  ## "greatest decimal `z` such that ``z*N == x and z*M == y``
  ## where N and M are positive integers."
  var (x,y) = (x,y)
  while y != 0:
    x = x mod y
    swap x, y
  abs x

proc lcm*[T](x, y: T): T =
  ## Computes the least common multiple of ``x`` and ``y``.
  x div gcd(x, y) * y

when isMainModule and not defined(JS):
  # Check for no side effect annotation
  proc mySqrt(num: float): float {.noSideEffect.} =
    return sqrt(num)

  # check gamma function
  assert($tgamma(5.0) == $24.0) # 4!
  assert(lgamma(1.0) == 0.0) # ln(1.0) == 0.0
  assert(erf(6.0) > erf(5.0))
  assert(erfc(6.0) < erfc(5.0))
when isMainModule:
  # Function for approximate comparison of floats
  proc `==~`(x, y: float): bool = (abs(x-y) < 1e-9)

  block: # round() tests
    # Round to 0 decimal places
    doAssert round(54.652) ==~ 55.0
    doAssert round(54.352) ==~ 54.0
    doAssert round(-54.652) ==~ -55.0
    doAssert round(-54.352) ==~ -54.0
    doAssert round(0.0) ==~ 0.0
    # Round to positive decimal places
    doAssert round(-547.652, 1) ==~ -547.7
    doAssert round(547.652, 1) ==~ 547.7
    doAssert round(-547.652, 2) ==~ -547.65
    doAssert round(547.652, 2) ==~ 547.65
    # Round to negative decimal places
    doAssert round(547.652, -1) ==~ 550.0
    doAssert round(547.652, -2) ==~ 500.0
    doAssert round(547.652, -3) ==~ 1000.0
    doAssert round(547.652, -4) ==~ 0.0
    doAssert round(-547.652, -1) ==~ -550.0
    doAssert round(-547.652, -2) ==~ -500.0
    doAssert round(-547.652, -3) ==~ -1000.0
    doAssert round(-547.652, -4) ==~ 0.0

  block: # splitDecimal() tests
    doAssert splitDecimal(54.674).intpart ==~ 54.0
    doAssert splitDecimal(54.674).floatpart ==~ 0.674
    doAssert splitDecimal(-693.4356).intpart ==~ -693.0
    doAssert splitDecimal(-693.4356).floatpart ==~ -0.4356
    doAssert splitDecimal(0.0).intpart ==~ 0.0
    doAssert splitDecimal(0.0).floatpart ==~ 0.0
