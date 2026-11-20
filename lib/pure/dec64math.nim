#
#
#            Nim's Runtime Library
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Elementary mathematical functions for `Dec64`.
##
## Transcendentals (`sqrt`, `exp`, `ln`, `sin`, …) are evaluated by
## round-tripping the operand through `float64` and delegating to
## `std/math`. The result is correct to roughly 15 decimal digits — one
## fewer than Dec64's native ~16.8-digit precision. For computations
## that must stay in pure decimal throughout (typically money), use
## the arithmetic operators in `std/dec64` directly; transcendentals
## here are intended for scientific or measurement-style work where
## the last ulp is noise.
##
## **Why float round-trip rather than a native decimal implementation?**
## Dec64 was designed for human-facing decimal values, but
## transcendentals have no exact decimal answer in the first place.
## `std/math` wraps `libm`, which is far more polished than anything we
## could hand-roll, and the 1-ulp loss at the last digit is invisible
## for trig/log/exp use cases. Decimal-exact operations
## (`floor`, `ceil`, `round`, `trunc`, `abs`, `sign`, integer-exponent
## `pow`) live in `std/dec64` itself and never touch float.
##
## See https://www.crockford.com/dec64.html for Dec64 itself.

runnableExamples:
  import std/dec64
  assert sqrt(4'dec) == 2'dec
  assert ln(1'dec) == 0'dec
  assert factorial(5) == 120'dec

import std/math
import std/dec64
import std/formatfloat
export dec64
when defined(nimPreviewSlimSystem):
  import std/assertions

func dec64FromFloat*(f: float): Dec64 =
  ## Convert a `float64` to Dec64 by scaling to ~16 significant decimal
  ## digits and rounding once. Used by the transcendental wrappers in this
  ## module: `math.sin`/`exp`/etc. already carry a ~1 ulp libm uncertainty,
  ## so the extra rounding from one scale-and-round step is below the
  ## noise floor.
  ##
  ## Roughly 2-3x faster than `dec64FromFloatPrecise` and allocates no
  ## string. May differ from the precise variant by 1-2 ulp in the 16th
  ## decimal digit. For round-trip-faithful conversion
  ## (`dec64FromFloat(toFloat(x)) == x` for the largest set of x), use
  ## `dec64FromFloatPrecise`.
  if f != f: return nan
  if f == Inf or f == -Inf: return nan
  if f == 0.0: return zero
  let af = if f < 0: -f else: f
  let mag = math.floor(math.log10(af)).int
  if mag > 143: return nan      # exceeds Dec64 representable range
  if mag < -143: return zero    # underflows Dec64
  # Aim for a 17-digit coefficient where it fits (|f's leading digit| < 3.6),
  # falling back to 16 digits otherwise — Dec64's coefficient holds about
  # 16.8 digits, so this captures full precision in the common case. Scale
  # by an exact integer power of 10 (10^k is exact in float64 for k <= 22).
  # For negative scales, divide by an exact power instead of multiplying by
  # an inexact tiny one — same trick as `toFloat`.
  let scale = 16 - mag
  var coeff: int64
  if scale >= 0:
    coeff = math.round(f * math.pow(10.0, scale.float)).int64
  else:
    coeff = math.round(f / math.pow(10.0, (-scale).float)).int64
  dec64(coeff, -scale)    # ctor canonicalizes / down-scales if > coeffMax

func dec64FromFloatPrecise*(f: float): Dec64 =
  ## Convert a `float64` to Dec64 via the float's shortest round-trip
  ## decimal string form (Dragonbox `$f` then `parse`). Produces the unique
  ## shortest decimal whose nearest float is `f`, so a sequence
  ## `toFloat(x).dec64FromFloatPrecise` recovers `x` for the largest
  ## possible set of `x`.
  ##
  ## Slower than `dec64FromFloat` (~150-300 ns vs. ~50-100 ns) and
  ## allocates a string. Use when round-trip fidelity matters more than
  ## throughput.
  if f != f: return nan
  if f == Inf or f == -Inf: return nan
  if f == 0.0: return zero
  parse($f)

func sqrt*(x: Dec64): Dec64 {.inline.} =
  ## Square root. `sqrt(-1) == nan`.
  dec64FromFloat(math.sqrt(x.toFloat))

func exp*(x: Dec64): Dec64 {.inline.} =
  ## `e^x`. Saturates to `nan` when the result exceeds Dec64's range.
  dec64FromFloat(math.exp(x.toFloat))

func ln*(x: Dec64): Dec64 {.inline.} =
  ## Natural logarithm. `ln(0) == nan`, `ln(<0) == nan`.
  dec64FromFloat(math.ln(x.toFloat))

template log*(x: Dec64): Dec64 = ln(x)
  ## Alias for `ln` (matches `std/math`).

func log2*(x: Dec64): Dec64 {.inline.} =
  dec64FromFloat(math.log2(x.toFloat))

func log10*(x: Dec64): Dec64 {.inline.} =
  dec64FromFloat(math.log10(x.toFloat))

func sin*(x: Dec64): Dec64 {.inline.} = dec64FromFloat(math.sin(x.toFloat))
func cos*(x: Dec64): Dec64 {.inline.} = dec64FromFloat(math.cos(x.toFloat))
func tan*(x: Dec64): Dec64 {.inline.} = dec64FromFloat(math.tan(x.toFloat))

func arcsin*(x: Dec64): Dec64 {.inline.} =
  dec64FromFloat(math.arcsin(x.toFloat))
func arccos*(x: Dec64): Dec64 {.inline.} =
  dec64FromFloat(math.arccos(x.toFloat))
func arctan*(x: Dec64): Dec64 {.inline.} =
  dec64FromFloat(math.arctan(x.toFloat))
func arctan2*(y, x: Dec64): Dec64 {.inline.} =
  dec64FromFloat(math.arctan2(y.toFloat, x.toFloat))

func sinh*(x: Dec64): Dec64 {.inline.} = dec64FromFloat(math.sinh(x.toFloat))
func cosh*(x: Dec64): Dec64 {.inline.} = dec64FromFloat(math.cosh(x.toFloat))
func tanh*(x: Dec64): Dec64 {.inline.} = dec64FromFloat(math.tanh(x.toFloat))

func pow*(base, exponent: Dec64): Dec64 {.inline.} =
  ## Dec64-exponent power. For integer exponents prefer
  ## `dec64.pow(Dec64, int)` which stays in pure decimal throughout.
  dec64FromFloat(math.pow(base.toFloat, exponent.toFloat))

func nthRoot*(x: Dec64, n: int): Dec64 {.inline.} =
  ## `x^(1/n)`. `nthRoot(8, 3) == 2`.
  if n == 0: return nan
  dec64FromFloat(math.pow(x.toFloat, 1.0 / n.float))

func factorial*(n: int): Dec64 =
  ## Exact integer factorial; stays in Dec64. Returns `nan` if the result
  ## overflows Dec64's representable range or if `n < 0`.
  if n < 0: return nan
  result = one
  for k in 2 .. n:
    result = result * dec64(k)
    if isNaN(result): return nan
