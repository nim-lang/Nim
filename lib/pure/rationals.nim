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

proc initRational*[T: SomeInteger](num, den: T): Rational[T] =
  ## Create a new rational number.
  assert(den != 0, "a denominator of zero value is invalid")
  result.num = num
  result.den = den

proc `//`*[T](num, den: T): Rational[T] = initRational[T](num, den)
  ## A friendlier version of `initRational`. Example usage:
  ##
  ## .. code-block:: nim
  ##   var x = 1//3 + 1//5

proc `$`*[T](x: Rational[T]): string =
  ## Turn a rational number into a string.
  result = $x.num & "/" & $x.den

proc toRational*[T: SomeInteger](x: T): Rational[T] =
  ## Convert some integer `x` to a rational number.
  result.num = x
  result.den = 1

proc toRational*(x: float,
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

proc toFloat*[T](x: Rational[T]): float =
  ## Convert a rational number `x` to a float.
  x.num / x.den

proc toInt*[T](x: Rational[T]): int =
  ## Convert a rational number `x` to an int. Conversion rounds towards 0 if
  ## `x` does not contain an integer value.
  x.num div x.den

proc reduce*[T: SomeInteger](x: var Rational[T]) =
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

proc `+` *[T](x, y: Rational[T]): Rational[T] =
  ## Add two rational numbers.
  let common = lcm(x.den, y.den)
  result.num = common div x.den * x.num + common div y.den * y.num
  result.den = common
  reduce(result)

proc `+` *[T](x: Rational[T], y: T): Rational[T] =
  ## Add rational `x` to int `y`.
  result.num = x.num + y * x.den
  result.den = x.den

proc `+` *[T](x: T, y: Rational[T]): Rational[T] =
  ## Add int `x` to rational `y`.
  result.num = x * y.den + y.num
  result.den = y.den

proc `+=` *[T](x: var Rational[T], y: Rational[T]) =
  ## Add rational `y` to rational `x`.
  let common = lcm(x.den, y.den)
  x.num = common div x.den * x.num + common div y.den * y.num
  x.den = common
  reduce(x)

proc `+=` *[T](x: var Rational[T], y: T) =
  ## Add int `y` to rational `x`.
  x.num += y * x.den

proc `-` *[T](x: Rational[T]): Rational[T] =
  ## Unary minus for rational numbers.
  result.num = -x.num
  result.den = x.den

proc `-` *[T](x, y: Rational[T]): Rational[T] =
  ## Subtract two rational numbers.
  let common = lcm(x.den, y.den)
  result.num = common div x.den * x.num - common div y.den * y.num
  result.den = common
  reduce(result)

proc `-` *[T](x: Rational[T], y: T): Rational[T] =
  ## Subtract int `y` from rational `x`.
  result.num = x.num - y * x.den
  result.den = x.den

proc `-` *[T](x: T, y: Rational[T]): Rational[T] =
  ## Subtract rational `y` from int `x`.
  result.num = x * y.den - y.num
  result.den = y.den

proc `-=` *[T](x: var Rational[T], y: Rational[T]) =
  ## Subtract rational `y` from rational `x`.
  let common = lcm(x.den, y.den)
  x.num = common div x.den * x.num - common div y.den * y.num
  x.den = common
  reduce(x)

proc `-=` *[T](x: var Rational[T], y: T) =
  ## Subtract int `y` from rational `x`.
  x.num -= y * x.den

proc `*` *[T](x, y: Rational[T]): Rational[T] =
  ## Multiply two rational numbers.
  result.num = x.num * y.num
  result.den = x.den * y.den
  reduce(result)

proc `*` *[T](x: Rational[T], y: T): Rational[T] =
  ## Multiply rational `x` with int `y`.
  result.num = x.num * y
  result.den = x.den
  reduce(result)

proc `*` *[T](x: T, y: Rational[T]): Rational[T] =
  ## Multiply int `x` with rational `y`.
  result.num = x * y.num
  result.den = y.den
  reduce(result)

proc `*=` *[T](x: var Rational[T], y: Rational[T]) =
  ## Multiply rationals `y` to `x`.
  x.num *= y.num
  x.den *= y.den
  reduce(x)

proc `*=` *[T](x: var Rational[T], y: T) =
  ## Multiply int `y` to rational `x`.
  x.num *= y
  reduce(x)

proc reciprocal*[T](x: Rational[T]): Rational[T] =
  ## Calculate the reciprocal of `x`. (1/x)
  if x.num > 0:
    result.num = x.den
    result.den = x.num
  elif x.num < 0:
    result.num = -x.den
    result.den = -x.num
  else:
    raise newException(DivByZeroDefect, "division by zero")

proc `/`*[T](x, y: Rational[T]): Rational[T] =
  ## Divide rationals `x` by `y`.
  result.num = x.num * y.den
  result.den = x.den * y.num
  reduce(result)

proc `/`*[T](x: Rational[T], y: T): Rational[T] =
  ## Divide rational `x` by int `y`.
  result.num = x.num
  result.den = x.den * y
  reduce(result)

proc `/`*[T](x: T, y: Rational[T]): Rational[T] =
  ## Divide int `x` by Rational `y`.
  result.num = x * y.den
  result.den = y.num
  reduce(result)

proc `/=`*[T](x: var Rational[T], y: Rational[T]) =
  ## Divide rationals `x` by `y` in place.
  x.num *= y.den
  x.den *= y.num
  reduce(x)

proc `/=`*[T](x: var Rational[T], y: T) =
  ## Divide rational `x` by int `y` in place.
  x.den *= y
  reduce(x)

proc cmp*(x, y: Rational): int =
  ## Compares two rationals.
  (x - y).num

proc `<` *(x, y: Rational): bool =
  (x - y).num < 0

proc `<=` *(x, y: Rational): bool =
  (x - y).num <= 0

proc `==` *(x, y: Rational): bool =
  (x - y).num == 0

proc abs*[T](x: Rational[T]): Rational[T] =
  result.num = abs x.num
  result.den = abs x.den

proc `div`*[T: SomeInteger](x, y: Rational[T]): T =
  ## Computes the rational truncated division.
  (x.num * y.den) div (y.num * x.den)

proc `mod`*[T: SomeInteger](x, y: Rational[T]): Rational[T] =
  ## Computes the rational modulo by truncated division (remainder).
  ## This is same as ``x - (x div y) * y``.
  result = ((x.num * y.den) mod (y.num * x.den)) // (x.den * y.den)
  reduce(result)

proc floorDiv*[T: SomeInteger](x, y: Rational[T]): T =
  ## Computes the rational floor division.
  ##
  ## Floor division is conceptually defined as ``floor(x / y)``.
  ## This is different from the ``div`` operator, which is defined
  ## as ``trunc(x / y)``. That is, ``div`` rounds towards ``0`` and ``floorDiv``
  ## rounds down.
  floorDiv(x.num * y.den, y.num * x.den)

proc floorMod*[T: SomeInteger](x, y: Rational[T]): Rational[T] =
  ## Computes the rational modulo by floor division (modulo).
  ##
  ## This is same as ``x - floorDiv(x, y) * y``.
  ## This proc behaves the same as the ``%`` operator in python.
  result = floorMod(x.num * y.den, y.num * x.den) // (x.den * y.den)
  reduce(result)

proc hash*[T](x: Rational[T]): Hash =
  ## Computes hash for rational `x`
  # reduce first so that hash(x) == hash(y) for x == y
  var copy = x
  reduce(copy)

  var h: Hash = 0
  h = h !& hash(copy.num)
  h = h !& hash(copy.den)
  result = !$h

when isMainModule:
  var
    z = Rational[int](num: 0, den: 1)
    o = initRational(num = 1, den = 1)
    a = initRational(1, 2)
    b = -1 // -2
    m1 = -1 // 1
    tt = 10 // 2

  assert(a == a)
  assert( (a-a) == z)
  assert( (a+b) == o)
  assert( (a/b) == o)
  assert( (a*b) == 1 // 4)
  assert( (3/a) == 6 // 1)
  assert( (a/3) == 1 // 6)
  assert(a*b == 1 // 4)
  assert(tt*z == z)
  assert(10*a == tt)
  assert(a*10 == tt)
  assert(tt/10 == a)
  assert(a-m1 == 3 // 2)
  assert(a+m1 == -1 // 2)
  assert(m1+tt == 16 // 4)
  assert(m1-tt == 6 // -1)

  assert(z < o)
  assert(z <= o)
  assert(z == z)
  assert(cmp(z, o) < 0)
  assert(cmp(o, z) > 0)

  assert(o == o)
  assert(o >= o)
  assert(not(o > o))
  assert(cmp(o, o) == 0)
  assert(cmp(z, z) == 0)
  assert(hash(o) == hash(o))

  assert(a == b)
  assert(a >= b)
  assert(not(b > a))
  assert(cmp(a, b) == 0)
  assert(hash(a) == hash(b))

  var x = 1//3

  x *= 5//1
  assert(x == 5//3)
  x += 2 // 9
  assert(x == 17//9)
  x -= 9//18
  assert(x == 25//18)
  x /= 1//2
  assert(x == 50//18)

  var y = 1//3

  y *= 4
  assert(y == 4//3)
  y += 5
  assert(y == 19//3)
  y -= 2
  assert(y == 13//3)
  y /= 9
  assert(y == 13//27)

  assert toRational(5) == 5//1
  assert abs(toFloat(y) - 0.4814814814814815) < 1.0e-7
  assert toInt(z) == 0

  when sizeof(int) == 8:
    assert toRational(0.98765432) == 2111111029 // 2137499919
    assert toRational(PI) == 817696623 // 260280919
  when sizeof(int) == 4:
    assert toRational(0.98765432) == 80 // 81
    assert toRational(PI) == 355 // 113

  assert toRational(0.1) == 1 // 10
  assert toRational(0.9) == 9 // 10

  assert toRational(0.0) == 0 // 1
  assert toRational(-0.25) == 1 // -4
  assert toRational(3.2) == 16 // 5
  assert toRational(0.33) == 33 // 100
  assert toRational(0.22) == 11 // 50
  assert toRational(10.0) == 10 // 1

  assert (1//1) div (3//10) == 3
  assert (-1//1) div (3//10) == -3
  assert (3//10) mod (1//1) == 3//10
  assert (-3//10) mod (1//1) == -3//10
  assert floorDiv(1//1, 3//10) == 3
  assert floorDiv(-1//1, 3//10) == -4
  assert floorMod(3//10, 1//1) == 3//10
  assert floorMod(-3//10, 1//1) == 7//10
