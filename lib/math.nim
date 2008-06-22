#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#



# math routines

# interface

{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!

{.push checks:off, line_dir:off, stack_trace:off.}

proc nextPowerOfTwo*(x: int): int
  ## returns the nearest power of two, so that
  ## result**2 >= x > (result-1)**2.
proc isPowerOfTwo*(x: int): bool {.noSideEffect.}
  ## returns true, if x is a power of two, false otherwise.
  ## Negative numbers are not a power of two.
proc countBits*(n: int32): int {.noSideEffect.}
  ## counts the set bits in `n`.

proc random*(max: int): int
  ## returns a random number in the range 0..max-1. The sequence of
  ## random number is always the same, unless `randomize` is called
  ## which initializes the random number generator with a "random"
  ## number, i.e. a tickcount.
proc randomize*()
  ## initializes the random number generator with a "random"
  ## number, i.e. a tickcount.

proc sqrt*(x: float): float {.importc: "sqrt", header: "<math.h>".}
  ## computes the square root of `x`.

proc ln*(x: float): float {.importc: "log", header: "<math.h>".}
  ## computes ln(x).
proc exp*(x: float): float {.importc: "exp", header: "<math.h>".}
  ## computes e**x.

proc frexp*(x: float, exponent: var int): float {.
  importc: "frexp", header: "<math.h>".}
  ## Split a number into mantissa and exponent.
  ## `frexp` calculates the mantissa m (a float greater than or equal to 0.5
  ## and less than 1) and the integer value n such that `x` (the original
  ## float value) equals m * 2**n. frexp stores n in `exponent` and returns
  ## m.

proc arccos*(x: float): float {.importc: "acos", header: "<math.h>".}
proc arcsin*(x: float): float {.importc: "asin", header: "<math.h>".}
proc arctan*(x: float): float {.importc: "atan", header: "<math.h>".}
proc arctan2*(y, x: float): float {.importc: "atan2", header: "<math.h>".}
  ## Calculate the arc tangent of `y` / `x`.
  ## `atan2` returns the arc tangent of `y` / `x`; it produces correct
  ## results even when the resulting angle is near pi/2 or -pi/2
  ## (`x` near 0).

proc cos*(x: float): float {.importc: "cos", header: "<math.h>".}
proc cosh*(x: float): float {.importc: "cosh", header: "<math.h>".}
proc hypot*(x: float): float {.importc: "hypot", header: "<math.h>".}
proc log10*(x: float): float {.importc: "log10", header: "<math.h>".}
proc sinh*(x: float): float {.importc: "sinh", header: "<math.h>".}
proc tan*(x: float): float {.importc: "tan", header: "<math.h>".}
proc tanh*(x: float): float {.importc: "tanh", header: "<math.h>".}
proc pow*(x, y: float): float {.importc: "pos", header: "<math.h>".}
  ## computes x to power raised of y.

type
  TFloatClass* = enum ## describes the class a floating point value belongs to.
                      ## This is the type that is returned by `classify`.
    fcNormal,    ## value is an ordinary nonzero floating point value
    fcSubnormal, ## value is a subnormal (a very small) floating point value
    fcZero,      ## value is zero
    fcNegZero,   ## value is the negative zero
    fcNan,       ## value is Not-A-Number (NAN)
    fcInf,       ## value is positive infinity
    fcNegInf     ## value is negative infinity

proc classify*(x: float): TFloatClass
  ## classifies a floating point value. Returns `x`'s class as specified by
  ## `TFloatClass`

# implementation

include cntbits

proc nextPowerOfTwo(x: int): int =
  result = x - 1
  when defined(cpu64):
    result = result or (result shr 32)
  result = result or (result shr 16)
  result = result or (result shr 8)
  result = result or (result shr 4)
  result = result or (result shr 2)
  result = result or (result shr 1)
  Inc(result)

# C procs:
proc gettime(dummy: ptr cint): cint {.
  importc: "time", header: "<time.h>".}
proc srand(seed: cint) {.
  importc: "srand", nodecl.}
proc rand(): cint {.importc: "rand", nodecl.}

# most C compilers have no classify:
proc classify(x: float): TFloatClass =
  if x == 0.0:
    if 1.0/x == 1.0/0.0:
      return fcZero
    else:
      return fcNegZero
  if x*0.5 == x:
    if x > 0.0: return fcInf
    else: return fcNegInf
  if x != x: return fcNan
  return fcNormal
  # XXX: fcSubnormal is not detected!

proc randomize() = srand(gettime(nil))
proc random(max: int): int = return rand() mod max

proc isPowerOfTwo(x: int): bool = return (x and -x) == x

{.pop.}
{.pop.}
