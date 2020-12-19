#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Dennis Felsing
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## This module implements rational numbers, consisting of a numerator `num` and
## a denominator `den`, both of type int. The denominator can not be 0.

import math
import hashes

type Rational*[T] = object
  ## a rational number, consisting of a numerator and denominator
  num*, den*: T

func initRational*[T: SomeInteger](num, den: T): Rational[T] =
  ## Create a new rational number.
  assert(den != 0, "a denominator of zero value is invalid")
  result.num = num
  result.den = den

func `//`*[T](num, den: T): Rational[T] = initRational[T](num, den)
  ## A friendlier version of `initRational`. Example usage:
  ##
  ## .. code-block:: nim
  ##   var x = 1//3 + 1//5

func `$`*[T](x: Rational[T]): string =
  ## Turn a rational number into a string.
  result = $x.num & "/" & $x.den

func toRational*[T: SomeInteger](x: T): Rational[T] =
  ## Convert some integer `x` to a rational number.
  result.num = x
  result.den = 1

func toRational*(x: float,
                 n: int = high(int) shr (sizeof(int) div 2 * 8)): Rational[int] =
  ## Calculates the best rational numerator and denominator
  ## that approximates to `x`, where the denominator is
  ## smaller than `n` (default is the largest possible
  ## int to give maximum resolution).
  ##
  ## The algorithm is based on the theory of continued fractions.
  ##
  ## .. code-block:: Nim
  ##  import math, rationals
  ##  for i in 1..10:
  ##    let t = (10 ^ (i+3)).int
  ##    let x = toRational(PI, t)
  ##    let newPI = x.num / x.den
  ##    echo x, " ", newPI, " error: ", PI - newPI, "  ", t

  # David Eppstein / UC Irvine / 8 Aug 1993
  # With corrections from Arno Formella, May 2008
  var
    m11, m22 = 1
    m12, m21 = 0
    ai = int(x)
    x = x
  while m21 * ai + m22 <= n:
    swap m12, m11
    swap m22, m21
    m11 = m12 * ai + m11
    m21 = m22 * ai + m21
    if x == float(ai): break # division by zero
    x = 1/(x - float(ai))
    if x > float(high(int32)): break # representation failure
    ai = int(x)
  result = m11 // m21

func toFloat*[T](x: Rational[T]): float =
  ## Convert a rational number `x` to a float.
  x.num / x.den

func toInt*[T](x: Rational[T]): int =
  ## Convert a rational number `x` to an int. Conversion rounds towards 0 if
  ## `x` does not contain an integer value.
  x.num div x.den

func reduce*[T: SomeInteger](x: var Rational[T]) =
  ## Reduce rational `x`.
  let common = gcd(x.num, x.den)
  if x.den > 0:
    x.num = x.num div common
    x.den = x.den div common
  elif x.den < 0:
    x.num = -x.num div common
    x.den = -x.den div common
  else:
    raise newException(DivByZeroDefect, "division by zero")

func `+` *[T](x, y: Rational[T]): Rational[T] =
  ## Add two rational numbers.
  let common = lcm(x.den, y.den)
  result.num = common div x.den * x.num + common div y.den * y.num
  result.den = common
  reduce(result)

func `+` *[T](x: Rational[T], y: T): Rational[T] =
  ## Add rational `x` to int `y`.
  result.num = x.num + y * x.den
  result.den = x.den

func `+` *[T](x: T, y: Rational[T]): Rational[T] =
  ## Add int `x` to rational `y`.
  result.num = x * y.den + y.num
  result.den = y.den

func `+=` *[T](x: var Rational[T], y: Rational[T]) =
  ## Add rational `y` to rational `x`.
  let common = lcm(x.den, y.den)
  x.num = common div x.den * x.num + common div y.den * y.num
  x.den = common
  reduce(x)

func `+=` *[T](x: var Rational[T], y: T) =
  ## Add int `y` to rational `x`.
  x.num += y * x.den

func `-` *[T](x: Rational[T]): Rational[T] =
  ## Unary minus for rational numbers.
  result.num = -x.num
  result.den = x.den

func `-` *[T](x, y: Rational[T]): Rational[T] =
  ## Subtract two rational numbers.
  let common = lcm(x.den, y.den)
  result.num = common div x.den * x.num - common div y.den * y.num
  result.den = common
  reduce(result)

func `-` *[T](x: Rational[T], y: T): Rational[T] =
  ## Subtract int `y` from rational `x`.
  result.num = x.num - y * x.den
  result.den = x.den

func `-` *[T](x: T, y: Rational[T]): Rational[T] =
  ## Subtract rational `y` from int `x`.
  result.num = x * y.den - y.num
  result.den = y.den

func `-=` *[T](x: var Rational[T], y: Rational[T]) =
  ## Subtract rational `y` from rational `x`.
  let common = lcm(x.den, y.den)
  x.num = common div x.den * x.num - common div y.den * y.num
  x.den = common
  reduce(x)

func `-=` *[T](x: var Rational[T], y: T) =
  ## Subtract int `y` from rational `x`.
  x.num -= y * x.den

func `*` *[T](x, y: Rational[T]): Rational[T] =
  ## Multiply two rational numbers.
  result.num = x.num * y.num
  result.den = x.den * y.den
  reduce(result)

func `*` *[T](x: Rational[T], y: T): Rational[T] =
  ## Multiply rational `x` with int `y`.
  result.num = x.num * y
  result.den = x.den
  reduce(result)

func `*` *[T](x: T, y: Rational[T]): Rational[T] =
  ## Multiply int `x` with rational `y`.
  result.num = x * y.num
  result.den = y.den
  reduce(result)

func `*=` *[T](x: var Rational[T], y: Rational[T]) =
  ## Multiply rationals `y` to `x`.
  x.num *= y.num
  x.den *= y.den
  reduce(x)

func `*=` *[T](x: var Rational[T], y: T) =
  ## Multiply int `y` to rational `x`.
  x.num *= y
  reduce(x)

func reciprocal*[T](x: Rational[T]): Rational[T] =
  ## Calculate the reciprocal of `x`. (1/x)
  if x.num > 0:
    result.num = x.den
    result.den = x.num
  elif x.num < 0:
    result.num = -x.den
    result.den = -x.num
  else:
    raise newException(DivByZeroDefect, "division by zero")

func `/`*[T](x, y: Rational[T]): Rational[T] =
  ## Divide rationals `x` by `y`.
  result.num = x.num * y.den
  result.den = x.den * y.num
  reduce(result)

func `/`*[T](x: Rational[T], y: T): Rational[T] =
  ## Divide rational `x` by int `y`.
  result.num = x.num
  result.den = x.den * y
  reduce(result)

func `/`*[T](x: T, y: Rational[T]): Rational[T] =
  ## Divide int `x` by Rational `y`.
  result.num = x * y.den
  result.den = y.num
  reduce(result)

func `/=`*[T](x: var Rational[T], y: Rational[T]) =
  ## Divide rationals `x` by `y` in place.
  x.num *= y.den
  x.den *= y.num
  reduce(x)

func `/=`*[T](x: var Rational[T], y: T) =
  ## Divide rational `x` by int `y` in place.
  x.den *= y
  reduce(x)

func cmp*(x, y: Rational): int =
  ## Compares two rationals.
  (x - y).num

func `<` *(x, y: Rational): bool =
  (x - y).num < 0

func `<=` *(x, y: Rational): bool =
  (x - y).num <= 0

func `==` *(x, y: Rational): bool =
  (x - y).num == 0

func abs*[T](x: Rational[T]): Rational[T] =
  result.num = abs x.num
  result.den = abs x.den

func `div`*[T: SomeInteger](x, y: Rational[T]): T =
  ## Computes the rational truncated division.
  (x.num * y.den) div (y.num * x.den)

func `mod`*[T: SomeInteger](x, y: Rational[T]): Rational[T] =
  ## Computes the rational modulo by truncated division (remainder).
  ## This is same as ``x - (x div y) * y``.
  result = ((x.num * y.den) mod (y.num * x.den)) // (x.den * y.den)
  reduce(result)

func floorDiv*[T: SomeInteger](x, y: Rational[T]): T =
  ## Computes the rational floor division.
  ##
  ## Floor division is conceptually defined as ``floor(x / y)``.
  ## This is different from the ``div`` operator, which is defined
  ## as ``trunc(x / y)``. That is, ``div`` rounds towards ``0`` and ``floorDiv``
  ## rounds down.
  floorDiv(x.num * y.den, y.num * x.den)

func floorMod*[T: SomeInteger](x, y: Rational[T]): Rational[T] =
  ## Computes the rational modulo by floor division (modulo).
  ##
  ## This is same as ``x - floorDiv(x, y) * y``.
  ## This func behaves the same as the ``%`` operator in python.
  result = floorMod(x.num * y.den, y.num * x.den) // (x.den * y.den)
  reduce(result)

func hash*[T](x: Rational[T]): Hash =
  ## Computes hash for rational `x`
  # reduce first so that hash(x) == hash(y) for x == y
  var copy = x
  reduce(copy)

  var h: Hash = 0
  h = h !& hash(copy.num)
  h = h !& hash(copy.den)
  result = !$h
