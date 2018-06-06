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

import bitops

proc binom*(n, k: int): int {.noSideEffect.} =
  ## Computes the binomial coefficient
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
  ## Computes the faculty/factorial function.
  const factTable =
    when sizeof(int) == 4:
      createFactTable[13]()
    else:
      createFactTable[21]()
  assert(n >= 0, $n & " must not be negative.")
  assert(n < factTable.len, $n & " is too large to look up in the table")
  factTable[n]

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

proc prod*[T](x: openArray[T]): T {.noSideEffect.} =
  ## Computes the product of the elements in ``x``.
  ## If ``x`` is empty, 1 is returned.
  result = 1.T
  for i in items(x): result = result * i

{.push noSideEffect.}
when not defined(JS): # C
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
  proc log2*(x: float32): float32 {.importc: "log2f", header: "<math.h>".}
  proc log2*(x: float64): float64 {.importc: "log2", header: "<math.h>".}
    ## Computes the binary logarithm (base 2) of `x`
  proc exp*(x: float32): float32 {.importc: "expf", header: "<math.h>".}
  proc exp*(x: float64): float64 {.importc: "exp", header: "<math.h>".}
    ## Computes the exponential function of `x` (pow(E, x))

  proc sin*(x: float32): float32 {.importc: "sinf", header: "<math.h>".}
  proc sin*(x: float64): float64 {.importc: "sin", header: "<math.h>".}
    ## Computes the sine of `x`
  proc cos*(x: float32): float32 {.importc: "cosf", header: "<math.h>".}
  proc cos*(x: float64): float64 {.importc: "cos", header: "<math.h>".}
    ## Computes the cosine of `x`
  proc tan*(x: float32): float32 {.importc: "tanf", header: "<math.h>".}
  proc tan*(x: float64): float64 {.importc: "tan", header: "<math.h>".}
    ## Computes the tangent of `x`

  proc sinh*(x: float32): float32 {.importc: "sinhf", header: "<math.h>".}
  proc sinh*(x: float64): float64 {.importc: "sinh", header: "<math.h>".}
    ## Computes the hyperbolic sine of `x`
  proc cosh*(x: float32): float32 {.importc: "coshf", header: "<math.h>".}
  proc cosh*(x: float64): float64 {.importc: "cosh", header: "<math.h>".}
    ## Computes the hyperbolic cosine of `x`
  proc tanh*(x: float32): float32 {.importc: "tanhf", header: "<math.h>".}
  proc tanh*(x: float64): float64 {.importc: "tanh", header: "<math.h>".}
    ## Computes the hyperbolic tangent of `x`

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

  proc arcsinh*(x: float32): float32 {.importc: "asinhf", header: "<math.h>".}
  proc arcsinh*(x: float64): float64 {.importc: "asinh", header: "<math.h>".}
    ## Computes the inverse hyperbolic sine of `x`
  proc arccosh*(x: float32): float32 {.importc: "acoshf", header: "<math.h>".}
  proc arccosh*(x: float64): float64 {.importc: "acosh", header: "<math.h>".}
    ## Computes the inverse hyperbolic cosine of `x`
  proc arctanh*(x: float32): float32 {.importc: "atanhf", header: "<math.h>".}
  proc arctanh*(x: float64): float64 {.importc: "atanh", header: "<math.h>".}
    ## Computes the inverse hyperbolic tangent of `x`

else: # JS
  proc sqrt*(x: float32): float32 {.importc: "Math.sqrt", nodecl.}
  proc sqrt*(x: float64): float64 {.importc: "Math.sqrt", nodecl.}

  proc ln*(x: float32): float32 {.importc: "Math.log", nodecl.}
  proc ln*(x: float64): float64 {.importc: "Math.log", nodecl.}
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
  proc arctan2*[T: float32|float64](y, x: T): T {.importC: "Math.atan2", nodecl.}

  proc arcsinh*[T: float32|float64](x: T): T {.importc: "Math.asinh", nodecl.}
  proc arccosh*[T: float32|float64](x: T): T {.importc: "Math.acosh", nodecl.}
  proc arctanh*[T: float32|float64](x: T): T {.importc: "Math.atanh", nodecl.}

proc cot*[T: float32|float64](x: T): T = 1.0 / tan(x)
  ## Computes the cotangent of `x`
proc sec*[T: float32|float64](x: T): T = 1.0 / cos(x)
  ## Computes the secant of `x`.
proc csc*[T: float32|float64](x: T): T = 1.0 / sin(x)
  ## Computes the cosecant of `x`

proc coth*[T: float32|float64](x: T): T = 1.0 / tanh(x)
  ## Computes the hyperbolic cotangent of `x`
proc sech*[T: float32|float64](x: T): T = 1.0 / cosh(x)
  ## Computes the hyperbolic secant of `x`
proc csch*[T: float32|float64](x: T): T = 1.0 / sinh(x)
  ## Computes the hyperbolic cosecant of `x`

proc arccot*[T: float32|float64](x: T): T = arctan(1.0 / x)
  ## Computes the inverse cotangent of `x`
proc arcsec*[T: float32|float64](x: T): T = arccos(1.0 / x)
  ## Computes the inverse secant of `x`
proc arccsc*[T: float32|float64](x: T): T = arcsin(1.0 / x)
  ## Computes the inverse cosecant of `x`

proc arccoth*[T: float32|float64](x: T): T = arctanh(1.0 / x)
  ## Computes the inverse hyperbolic cotangent of `x`
proc arcsech*[T: float32|float64](x: T): T = arccosh(1.0 / x)
  ## Computes the inverse hyperbolic secant of `x`
proc arccsch*[T: float32|float64](x: T): T = arcsinh(1.0 / x)
  ## Computes the inverse hyperbolic cosecant of `x`

when not defined(JS): # C
  proc hypot*(x, y: float32): float32 {.importc: "hypotf", header: "<math.h>".}
  proc hypot*(x, y: float64): float64 {.importc: "hypot", header: "<math.h>".}
    ## Computes the hypotenuse of a right-angle triangle with `x` and
    ## `y` as its base and height. Equivalent to ``sqrt(x*x + y*y)``.

  proc pow*(x, y: float32): float32 {.importc: "powf", header: "<math.h>".}
  proc pow*(x, y: float64): float64 {.importc: "pow", header: "<math.h>".}
    ## computes x to power raised of y.
    ##
    ## To compute power between integers, use `^` e.g. 2 ^ 6

  proc erf*(x: float32): float32 {.importc: "erff", header: "<math.h>".}
  proc erf*(x: float64): float64 {.importc: "erf", header: "<math.h>".}
    ## The error function
  proc erfc*(x: float32): float32 {.importc: "erfcf", header: "<math.h>".}
  proc erfc*(x: float64): float64 {.importc: "erfc", header: "<math.h>".}
    ## The complementary error function

  proc gamma*(x: float32): float32 {.importc: "tgammaf", header: "<math.h>".}
  proc gamma*(x: float64): float64 {.importc: "tgamma", header: "<math.h>".}
    ## The gamma function
  proc tgamma*(x: float32): float32
    {.deprecated: "use gamma instead", importc: "tgammaf", header: "<math.h>".}
  proc tgamma*(x: float64): float64
    {.deprecated: "use gamma instead", importc: "tgamma", header: "<math.h>".}
    ## The gamma function
    ## **Deprecated since version 0.19.0**: Use ``gamma`` instead.
  proc lgamma*(x: float32): float32 {.importc: "lgammaf", header: "<math.h>".}
  proc lgamma*(x: float64): float64 {.importc: "lgamma", header: "<math.h>".}
    ## Natural log of the gamma function

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

  when defined(windows) and (defined(vcc) or defined(bcc)):
    # MSVC 2010 don't have trunc/truncf
    # this implementation was inspired by Go-lang Math.Trunc
    proc truncImpl(f: float64): float64 =
      const
        mask : uint64 = 0x7FF
        shift: uint64 = 64 - 12
        bias : uint64 = 0x3FF

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
        mask : uint32 = 0xFF
        shift: uint32 = 32 - 9
        bias : uint32 = 0x7F

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

    proc round0[T: float32|float64](x: T): T =
      ## Windows compilers prior to MSVC 2012 do not implement 'round',
      ## 'roundl' or 'roundf'.
      result = if x < 0.0: ceil(x - T(0.5)) else: floor(x + T(0.5))
  else:
    proc round0(x: float32): float32 {.importc: "roundf", header: "<math.h>".}
    proc round0(x: float64): float64 {.importc: "round", header: "<math.h>".}
      ## Rounds a float to zero decimal places.  Used internally by the round
      ## function when the specified number of places is 0.

    proc trunc*(x: float32): float32 {.importc: "truncf", header: "<math.h>".}
    proc trunc*(x: float64): float64 {.importc: "trunc", header: "<math.h>".}
      ## Truncates `x` to the decimal point
      ##
      ## .. code-block:: nim
      ##  echo trunc(PI) # 3.0

  proc fmod*(x, y: float32): float32 {.deprecated, importc: "fmodf", header: "<math.h>".}
  proc fmod*(x, y: float64): float64 {.deprecated, importc: "fmod", header: "<math.h>".}
    ## Computes the remainder of `x` divided by `y`
    ##
    ## .. code-block:: nim
    ##  echo fmod(-2.5, 0.3) ## -0.1

  proc `mod`*(x, y: float32): float32 {.importc: "fmodf", header: "<math.h>".}
  proc `mod`*(x, y: float64): float64 {.importc: "fmod", header: "<math.h>".}
    ## Computes the modulo operation for float operators.
else: # JS
  proc hypot*[T: float32|float64](x, y: T): T = return sqrt(x*x + y*y)
  proc pow*(x, y: float32): float32 {.importC: "Math.pow", nodecl.}
  proc pow*(x, y: float64): float64 {.importc: "Math.pow", nodecl.}
  proc floor*(x: float32): float32 {.importc: "Math.floor", nodecl.}
  proc floor*(x: float64): float64 {.importc: "Math.floor", nodecl.}
  proc ceil*(x: float32): float32 {.importc: "Math.ceil", nodecl.}
  proc ceil*(x: float64): float64 {.importc: "Math.ceil", nodecl.}
  proc round0(x: float): float {.importc: "Math.round", nodecl.}
  proc trunc*(x: float32): float32 {.importc: "Math.trunc", nodecl.}
  proc trunc*(x: float64): float64 {.importc: "Math.trunc", nodecl.}

  proc `mod`*(x, y: float32): float32 {.importcpp: "# % #".}
  proc `mod`*(x, y: float64): float64 {.importcpp: "# % #".}
  ## Computes the modulo operation for float operators.

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

proc floorDiv*[T: SomeInteger](x, y: T): T =
  ## Floor division is conceptually defined as ``floor(x / y)``.
  ## This is different from the ``div`` operator, which is defined
  ## as ``trunc(x / y)``. That is, ``div`` rounds towards ``0`` and ``floorDiv``
  ## rounds down.
  result = x div y
  let r = x mod y
  if (r > 0 and y < 0) or (r < 0 and y > 0): result.dec 1

proc floorMod*[T: SomeNumber](x, y: T): T =
  ## Floor modulus is conceptually defined as ``x - (floorDiv(x, y) * y).
  ## This proc behaves the same as the ``%`` operator in python.
  result = x mod y
  if (result > 0 and y < 0) or (result < 0 and y > 0): result += y

when not defined(JS):
  proc c_frexp*(x: float32, exponent: var int32): float32 {.
    importc: "frexp", header: "<math.h>".}
  proc c_frexp*(x: float64, exponent: var int32): float64 {.
    importc: "frexp", header: "<math.h>".}
  proc frexp*[T, U](x: T, exponent: var U): T =
    ## Split a number into mantissa and exponent.
    ## `frexp` calculates the mantissa m (a float greater than or equal to 0.5
    ## and less than 1) and the integer value n such that `x` (the original
    ## float value) equals m * 2**n. frexp stores n in `exponent` and returns
    ## m.
    var exp: int32
    result = c_frexp(x, exp)
    exponent = exp
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

proc sgn*[T: SomeNumber](x: T): int {.inline.} =
  ## Sign function. Returns -1 for negative numbers and `NegInf`, 1 for
  ## positive numbers and `Inf`, and 0 for positive zero, negative zero and
  ## `NaN`.
  ord(T(0) < x) - ord(x < T(0))

{.pop.}
{.pop.}

proc `^`*[T](x: T, y: Natural): T =
  ## Computes ``x`` to the power ``y`. ``x`` must be non-negative, use
  ## `pow <#pow,float,float>` for negative exponents.
  when compiles(y >= T(0)):
    assert y >= T(0)
  else:
    assert T(y) >= T(0)
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
  ## Note that for floats, the result cannot always be interpreted as
  ## "greatest decimal `z` such that ``z*N == x and z*M == y``
  ## where N and M are positive integers."
  var (x, y) = (x, y)
  while y != 0:
    x = x mod y
    swap x, y
  abs x

proc gcd*(x, y: SomeInteger): SomeInteger =
  ## Computes the greatest common (positive) divisor of ``x`` and ``y``.
  ## Using binary GCD (aka Stein's) algorithm.
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

proc lcm*[T](x, y: T): T =
  ## Computes the least common multiple of ``x`` and ``y``.
  x div gcd(x, y) * y

when isMainModule and not defined(JS):
  # Check for no side effect annotation
  proc mySqrt(num: float): float {.noSideEffect.} =
    return sqrt(num)

  # check gamma function
  assert(gamma(5.0) == 24.0) # 4!
  assert($tgamma(5.0) == $24.0) # 4!
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
    except AssertionError:
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
