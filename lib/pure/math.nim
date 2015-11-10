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
when not defined(js) and not defined(nimscript):
  import times

const
  PI* = 3.1415926535897932384626433 ## the circle constant PI (Ludolph's number)
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

proc random*(max: int): int {.benign.}
  ## Returns a random number in the range 0..max-1. The sequence of
  ## random number is always the same, unless `randomize` is called
  ## which initializes the random number generator with a "random"
  ## number, i.e. a tickcount.

proc random*(max: float): float {.benign.}
  ## Returns a random number in the range 0..<max. The sequence of
  ## random number is always the same, unless `randomize` is called
  ## which initializes the random number generator with a "random"
  ## number, i.e. a tickcount. This has a 16-bit resolution on windows
  ## and a 48-bit resolution on other platforms.

when not defined(nimscript):
  proc randomize*() {.benign.}
    ## Initializes the random number generator with a "random"
    ## number, i.e. a tickcount. Note: Does nothing for the JavaScript target,
    ## as JavaScript does not support this. Nor does it work for NimScript.

proc randomize*(seed: int) {.benign.}
  ## Initializes the random number generator with a specific seed.
  ## Note: Does nothing for the JavaScript target,
  ## as JavaScript does not support this.

{.push noSideEffect.}
when not defined(JS):
  proc sqrt*(x: float): float {.importc: "sqrt", header: "<math.h>".}
    ## Computes the square root of `x`.
  proc cbrt*(x: float): float {.importc: "cbrt", header: "<math.h>".}
    ## Computes the cubic root of `x`

  proc ln*(x: float): float {.importc: "log", header: "<math.h>".}
    ## Computes the natural log of `x`
  proc log10*(x: float): float {.importc: "log10", header: "<math.h>".}
    ## Computes the common logarithm (base 10) of `x`
  proc log2*(x: float): float = return ln(x) / ln(2.0)
    ## Computes the binary logarithm (base 2) of `x`
  proc exp*(x: float): float {.importc: "exp", header: "<math.h>".}
    ## Computes the exponential function of `x` (pow(E, x))

  proc frexp*(x: float, exponent: var int): float {.
    importc: "frexp", header: "<math.h>".}
    ## Split a number into mantissa and exponent.
    ## `frexp` calculates the mantissa m (a float greater than or equal to 0.5
    ## and less than 1) and the integer value n such that `x` (the original
    ## float value) equals m * 2**n. frexp stores n in `exponent` and returns
    ## m.

  proc round*(x: float): int {.importc: "lrint", header: "<math.h>".}
    ## Converts a float to an int by rounding.

  proc arccos*(x: float): float {.importc: "acos", header: "<math.h>".}
    ## Computes the arc cosine of `x`
  proc arcsin*(x: float): float {.importc: "asin", header: "<math.h>".}
    ## Computes the arc sine of `x`
  proc arctan*(x: float): float {.importc: "atan", header: "<math.h>".}
    ## Calculate the arc tangent of `y` / `x`
  proc arctan2*(y, x: float): float {.importc: "atan2", header: "<math.h>".}
    ## Calculate the arc tangent of `y` / `x`.
    ## `atan2` returns the arc tangent of `y` / `x`; it produces correct
    ## results even when the resulting angle is near pi/2 or -pi/2
    ## (`x` near 0).

  proc cos*(x: float): float {.importc: "cos", header: "<math.h>".}
    ## Computes the cosine of `x`
  proc cosh*(x: float): float {.importc: "cosh", header: "<math.h>".}
    ## Computes the hyperbolic cosine of `x`
  proc hypot*(x, y: float): float {.importc: "hypot", header: "<math.h>".}
    ## Computes the hypotenuse of a right-angle triangle with `x` and
    ## `y` as its base and height. Equivalent to ``sqrt(x*x + y*y)``.

  proc sinh*(x: float): float {.importc: "sinh", header: "<math.h>".}
    ## Computes the hyperbolic sine of `x`
  proc sin*(x: float): float {.importc: "sin", header: "<math.h>".}
    ## Computes the sine of `x`
  proc tan*(x: float): float {.importc: "tan", header: "<math.h>".}
    ## Computes the tangent of `x`
  proc tanh*(x: float): float {.importc: "tanh", header: "<math.h>".}
    ## Computes the hyperbolic tangent of `x`
  proc pow*(x, y: float): float {.importc: "pow", header: "<math.h>".}
    ## Computes `x` to power of `y`.

  proc erf*(x: float): float {.importc: "erf", header: "<math.h>".}
    ## The error function
  proc erfc*(x: float): float {.importc: "erfc", header: "<math.h>".}
    ## The complementary error function

  proc lgamma*(x: float): float {.importc: "lgamma", header: "<math.h>".}
    ## Natural log of the gamma function
  proc tgamma*(x: float): float {.importc: "tgamma", header: "<math.h>".}
    ## The gamma function

  # C procs:
  when defined(vcc) and false:
    # The "secure" random, available from Windows XP
    # https://msdn.microsoft.com/en-us/library/sxtz2fa8.aspx
    # Present in some variants of MinGW but not enough to justify
    # `when defined(windows)` yet
    proc rand_s(val: var cuint) {.importc: "rand_s", header: "<stdlib.h>".}
    # To behave like the normal version
    proc rand(): cuint = rand_s(result)
  else:
    proc srand(seed: cint) {.importc: "srand", header: "<stdlib.h>".}
    proc rand(): cint {.importc: "rand", header: "<stdlib.h>".}

  when not defined(windows):
    proc srand48(seed: clong) {.importc: "srand48", header: "<stdlib.h>".}
    proc drand48(): float {.importc: "drand48", header: "<stdlib.h>".}
    proc random(max: float): float =
      result = drand48() * max
  else:
    when defined(vcc): # Windows with Visual C
      proc random(max: float): float =
        # we are hardcoding this because
        # importc-ing macros is extremely problematic
        # and because the value is publicly documented
        # on MSDN and very unlikely to change
        # See https://msdn.microsoft.com/en-us/library/296az74e.aspx
        const rand_max = 4294967295 # UINT_MAX
        result = (float(rand()) / float(rand_max)) * max
      proc randomize() = discard
      proc randomize(seed: int) = discard
    else: # Windows with another compiler
      proc random(max: float): float =
        # we are hardcoding this because
        # importc-ing macros is extremely problematic
        # and because the value is publicly documented
        # on MSDN and very unlikely to change
        const rand_max = 32767
        result = (float(rand()) / float(rand_max)) * max

  when not defined(vcc): # the above code for vcc uses `discard` instead
    # this is either not Windows or is Windows without vcc
    when not defined(nimscript):
      proc randomize() =
        randomize(cast[int](epochTime()))
    proc randomize(seed: int) =
      srand(cint(seed)) # rand_s doesn't use srand
      when declared(srand48): srand48(seed)

  proc random(max: int): int =
    result = int(rand()) mod max

  proc trunc*(x: float): float {.importc: "trunc", header: "<math.h>".}
    ## Truncates `x` to the decimal point
    ##
    ## .. code-block:: nim
    ##  echo trunc(PI) # 3.0
  proc floor*(x: float): float {.importc: "floor", header: "<math.h>".}
    ## Computes the floor function (i.e., the largest integer not greater than `x`)
    ##
    ## .. code-block:: nim
    ##  echo floor(-3.5) ## -4.0
  proc ceil*(x: float): float {.importc: "ceil", header: "<math.h>".}
    ## Computes the ceiling function (i.e., the smallest integer not less than `x`)
    ##
    ## .. code-block:: nim
    ##  echo ceil(-2.1) ## -2.0

  proc fmod*(x, y: float): float {.importc: "fmod", header: "<math.h>".}
    ## Computes the remainder of `x` divided by `y`
    ##
    ## .. code-block:: nim
    ##  echo fmod(-2.5, 0.3) ## -0.1

else:
  proc mathrandom(): float {.importc: "Math.random", nodecl.}
  proc floor*(x: float): float {.importc: "Math.floor", nodecl.}
  proc ceil*(x: float): float {.importc: "Math.ceil", nodecl.}
  proc random(max: int): int =
    result = int(floor(mathrandom() * float(max)))
  proc random(max: float): float =
    result = float(mathrandom() * float(max))
  proc randomize() = discard
  proc randomize(seed: int) = discard

  proc sqrt*(x: float): float {.importc: "Math.sqrt", nodecl.}
  proc ln*(x: float): float {.importc: "Math.log", nodecl.}
  proc log10*(x: float): float = return ln(x) / ln(10.0)
  proc log2*(x: float): float = return ln(x) / ln(2.0)

  proc exp*(x: float): float {.importc: "Math.exp", nodecl.}
  proc round*(x: float): int {.importc: "Math.round", nodecl.}
  proc pow*(x, y: float): float {.importc: "Math.pow", nodecl.}

  proc frexp*(x: float, exponent: var int): float =
    if x == 0.0:
      exponent = 0
      result = 0.0
    elif x < 0.0:
      result = -frexp(-x, exponent)
    else:
      var ex = floor(log2(x))
      exponent = round(ex)
      result = x / pow(2.0, ex)

  proc arccos*(x: float): float {.importc: "Math.acos", nodecl.}
  proc arcsin*(x: float): float {.importc: "Math.asin", nodecl.}
  proc arctan*(x: float): float {.importc: "Math.atan", nodecl.}
  proc arctan2*(y, x: float): float {.importc: "Math.atan2", nodecl.}

  proc cos*(x: float): float {.importc: "Math.cos", nodecl.}
  proc cosh*(x: float): float = return (exp(x)+exp(-x))*0.5
  proc hypot*(x, y: float): float = return sqrt(x*x + y*y)
  proc sinh*(x: float): float = return (exp(x)-exp(-x))*0.5
  proc sin*(x: float): float {.importc: "Math.sin", nodecl.}
  proc tan*(x: float): float {.importc: "Math.tan", nodecl.}
  proc tanh*(x: float): float =
    var y = exp(2.0*x)
    return (y-1.0)/(y+1.0)

{.pop.}

proc degToRad*[T: float32|float64](d: T): T {.inline.} =
  ## Convert from degrees to radians
  result = T(d) * RadPerDeg

proc radToDeg*[T: float32|float64](d: T): T {.inline.} =
  ## Convert from radians to degrees
  result = T(d) / RadPerDeg

proc `mod`*(x, y: float): float =
  ## Computes the modulo operation for float operators. Equivalent
  ## to ``x - y * floor(x/y)``. Note that the remainder will always
  ## have the same sign as the divisor.
  ##
  ## .. code-block:: nim
  ##  echo (4.0 mod -3.1) # -2.2
  result = if y == 0.0: x else: x - y * (x/y).floor

proc random*[T](x: Slice[T]): T =
  ## For a slice `a .. b` returns a value in the range `a .. b-1`.
  result = random(x.b - x.a) + x.a

proc random*[T](a: openArray[T]): T =
  ## returns a random element from the openarray `a`.
  result = a[random(a.low..a.len)]

{.pop.}
{.pop.}

proc `^`*[T](x, y: T): T =
  ## Computes ``x`` to the power ``y`. ``x`` must be non-negative, use
  ## `pow <#pow,float,float>` for negative exponents.
  assert y >= 0
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
  proc gettime(dummy: ptr cint): cint {.importc: "time", header: "<time.h>".}

  # Verifies random seed initialization.
  let seed = gettime(nil)
  randomize(seed)
  const SIZE = 10
  var buf : array[0..SIZE, int]
  # Fill the buffer with random values
  for i in 0..SIZE-1:
    buf[i] = random(high(int))
  # Check that the second random calls are the same for each position.
  randomize(seed)
  for i in 0..SIZE-1:
    assert buf[i] == random(high(int)), "non deterministic random seeding"

  when not defined(testing):
    echo "random values equal after reseeding"

  # Check for no side effect annotation
  proc mySqrt(num: float): float {.noSideEffect.} =
    return sqrt(num)

  # check gamma function
  assert($tgamma(5.0) == $24.0) # 4!
  assert(lgamma(1.0) == 0.0) # ln(1.0) == 0.0
  assert(erf(6.0) > erf(5.0))
  assert(erfc(6.0) < erfc(5.0))
