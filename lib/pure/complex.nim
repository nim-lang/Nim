#
#
#            Nim's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements complex numbers
## and basic mathematical operations on them.
##
## Complex numbers are currently generic over 64-bit or 32-bit floats.

runnableExamples:
  from std/math import almostEqual, sqrt

  func almostEqual(a, b: Complex): bool =
    almostEqual(a.re, b.re) and almostEqual(a.im, b.im)

  let
    z1 = complex(1.0, 2.0)
    z2 = complex(3.0, -4.0)

  assert almostEqual(z1 + z2, complex(4.0, -2.0))
  assert almostEqual(z1 - z2, complex(-2.0, 6.0))
  assert almostEqual(z1 * z2, complex(11.0, 2.0))
  assert almostEqual(z1 / z2, complex(-0.2, 0.4))

  assert almostEqual(abs(z1), sqrt(5.0))
  assert almostEqual(conjugate(z1), complex(1.0, -2.0))

  let (r, phi) = z1.polar
  assert almostEqual(rect(r, phi), z1)

{.push checks: off, line_dir: off, stack_trace: off, debugger: off.}
# the user does not want to trace a part of the standard library!

import math

type
  Complex*[T: SomeFloat] = object
    ## A complex number, consisting of a real and an imaginary part.
    re*, im*: T
  Complex64* = Complex[float64]
    ## Alias for a complex number using 64-bit floats.
  Complex32* = Complex[float32]
    ## Alias for a complex number using 32-bit floats.

func complex*[T: SomeFloat](re: T; im: T = 0.0): Complex[T] =
  ## Returns a `Complex[T]` with real part `re` and imaginary part `im`.
  result.re = re
  result.im = im

func complex32*(re: float32; im: float32 = 0.0): Complex32 =
  ## Returns a `Complex32` with real part `re` and imaginary part `im`.
  result.re = re
  result.im = im

func complex64*(re: float64; im: float64 = 0.0): Complex64 =
  ## Returns a `Complex64` with real part `re` and imaginary part `im`.
  result.re = re
  result.im = im

template im*(arg: typedesc[float32]): Complex32 = complex32(0, 1)
  ## Returns the imaginary unit (`complex32(0, 1)`).
template im*(arg: typedesc[float64]): Complex64 = complex64(0, 1)
  ## Returns the imaginary unit (`complex64(0, 1)`).
template im*(arg: float32): Complex32 = complex32(0, arg)
  ## Returns `arg` as an imaginary number (`complex32(0, arg)`).
template im*(arg: float64): Complex64 = complex64(0, arg)
  ## Returns `arg` as an imaginary number (`complex64(0, arg)`).

func abs*[T](z: Complex[T]): T =
  ## Returns the absolute value of `z`,
  ## that is the distance from (0, 0) to `z`.
  result = hypot(z.re, z.im)

func abs2*[T](z: Complex[T]): T =
  ## Returns the squared absolute value of `z`,
  ## that is the squared distance from (0, 0) to `z`.
  ## This is more efficient than `abs(z) ^ 2`.
  result = z.re * z.re + z.im * z.im

func conjugate*[T](z: Complex[T]): Complex[T] =
  ## Returns the complex conjugate of `z` (`complex(z.re, -z.im)`).
  result.re = z.re
  result.im = -z.im

func inv*[T](z: Complex[T]): Complex[T] =
  ## Returns the multiplicative inverse of `z` (`1/z`).
  conjugate(z) / abs2(z)

func `==`*[T](x, y: Complex[T]): bool =
  ## Compares two complex numbers for equality.
  result = x.re == y.re and x.im == y.im

func `+`*[T](x: T; y: Complex[T]): Complex[T] =
  ## Adds a real number to a complex number.
  result.re = x + y.re
  result.im = y.im

func `+`*[T](x: Complex[T]; y: T): Complex[T] =
  ## Adds a complex number to a real number.
  result.re = x.re + y
  result.im = x.im

func `+`*[T](x, y: Complex[T]): Complex[T] =
  ## Adds two complex numbers.
  result.re = x.re + y.re
  result.im = x.im + y.im

func `-`*[T](z: Complex[T]): Complex[T] =
  ## Unary minus for complex numbers.
  result.re = -z.re
  result.im = -z.im

func `-`*[T](x: T; y: Complex[T]): Complex[T] =
  ## Subtracts a complex number from a real number.
  result.re = x - y.re
  result.im = -y.im

func `-`*[T](x: Complex[T]; y: T): Complex[T] =
  ## Subtracts a real number from a complex number.
  result.re = x.re - y
  result.im = x.im

func `-`*[T](x, y: Complex[T]): Complex[T] =
  ## Subtracts two complex numbers.
  result.re = x.re - y.re
  result.im = x.im - y.im

func `*`*[T](x: T; y: Complex[T]): Complex[T] =
  ## Multiplies a real number with a complex number.
  result.re = x * y.re
  result.im = x * y.im

func `*`*[T](x: Complex[T]; y: T): Complex[T] =
  ## Multiplies a complex number with a real number.
  result.re = x.re * y
  result.im = x.im * y

func `*`*[T](x, y: Complex[T]): Complex[T] =
  ## Multiplies two complex numbers.
  result.re = x.re * y.re - x.im * y.im
  result.im = x.im * y.re + x.re * y.im

func `/`*[T](x: Complex[T]; y: T): Complex[T] =
  ## Divides a complex number by a real number.
  result.re = x.re / y
  result.im = x.im / y

func `/`*[T](x: T; y: Complex[T]): Complex[T] =
  ## Divides a real number by a complex number.
  result = x * inv(y)

func `/`*[T](x, y: Complex[T]): Complex[T] =
  ## Divides two complex numbers.
  var r, den: T
  if abs(y.re) < abs(y.im):
    r = y.re / y.im
    den = y.im + r * y.re
    result.re = (x.re * r + x.im) / den
    result.im = (x.im * r - x.re) / den
  else:
    r = y.im / y.re
    den = y.re + r * y.im
    result.re = (x.re + r * x.im) / den
    result.im = (x.im - r * x.re) / den


func `+=`*[T](x: var Complex[T]; y: Complex[T]) =
  ## Adds `y` to `x`.
  x.re += y.re
  x.im += y.im

func `-=`*[T](x: var Complex[T]; y: Complex[T]) =
  ## Subtracts `y` from `x`.
  x.re -= y.re
  x.im -= y.im

func `*=`*[T](x: var Complex[T]; y: Complex[T]) =
  ## Multiplies `x` by `y`.
  let im = x.im * y.re + x.re * y.im
  x.re = x.re * y.re - x.im * y.im
  x.im = im

func `/=`*[T](x: var Complex[T]; y: Complex[T]) =
  ## Divides `x` by `y` in place.
  x = x / y


func sqrt*[T](z: Complex[T]): Complex[T] =
  ## Computes the
  ## ([principal](https://en.wikipedia.org/wiki/Square_root#Principal_square_root_of_a_complex_number))
  ## square root of a complex number `z`.
  var x, y, w, r: T

  if z.re == 0.0 and z.im == 0.0:
    result = z
  else:
    x = abs(z.re)
    y = abs(z.im)
    if x >= y:
      r = y / x
      w = sqrt(x) * sqrt(0.5 * (1.0 + sqrt(1.0 + r * r)))
    else:
      r = x / y
      w = sqrt(y) * sqrt(0.5 * (r + sqrt(1.0 + r * r)))

    if z.re >= 0.0:
      result.re = w
      result.im = z.im / (w * 2.0)
    else:
      result.im = if z.im >= 0.0: w else: -w
      result.re = z.im / (result.im + result.im)

func exp*[T](z: Complex[T]): Complex[T] =
  ## Computes the exponential function (`e^z`).
  let
    rho = exp(z.re)
    theta = z.im
  result.re = rho * cos(theta)
  result.im = rho * sin(theta)

func ln*[T](z: Complex[T]): Complex[T] =
  ## Returns the
  ## ([principal value](https://en.wikipedia.org/wiki/Complex_logarithm#Principal_value)
  ## of the) natural logarithm of `z`.
  result.re = ln(abs(z))
  result.im = arctan2(z.im, z.re)

func log10*[T](z: Complex[T]): Complex[T] =
  ## Returns the logarithm base 10 of `z`.
  ##
  ## **See also:**
  ## * `ln func<#ln,Complex[T]>`_
  result = ln(z) / ln(10.0)

func log2*[T](z: Complex[T]): Complex[T] =
  ## Returns the logarithm base 2 of `z`.
  ##
  ## **See also:**
  ## * `ln func<#ln,Complex[T]>`_
  result = ln(z) / ln(2.0)

func pow*[T](x, y: Complex[T]): Complex[T] =
  ## `x` raised to the power of `y`.
  if x.re == 0.0 and x.im == 0.0:
    if y.re == 0.0 and y.im == 0.0:
      result.re = 1.0
      result.im = 0.0
    else:
      result.re = 0.0
      result.im = 0.0
  elif y.re == 1.0 and y.im == 0.0:
    result = x
  elif y.re == -1.0 and y.im == 0.0:
    result = T(1.0) / x
  else:
    let
      rho = abs(x)
      theta = arctan2(x.im, x.re)
      s = pow(rho, y.re) * exp(-y.im * theta)
      r = y.re * theta + y.im * ln(rho)
    result.re = s * cos(r)
    result.im = s * sin(r)

func pow*[T](x: Complex[T]; y: T): Complex[T] =
  ## The complex number `x` raised to the power of the real number `y`.
  pow(x, complex[T](y))


func sin*[T](z: Complex[T]): Complex[T] =
  ## Returns the sine of `z`.
  result.re = sin(z.re) * cosh(z.im)
  result.im = cos(z.re) * sinh(z.im)

func arcsin*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse sine of `z`.
  result = -im(T) * ln(im(T) * z + sqrt(T(1.0) - z*z))

func cos*[T](z: Complex[T]): Complex[T] =
  ## Returns the cosine of `z`.
  result.re = cos(z.re) * cosh(z.im)
  result.im = -sin(z.re) * sinh(z.im)

func arccos*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse cosine of `z`.
  result = -im(T) * ln(z + sqrt(z*z - T(1.0)))

func tan*[T](z: Complex[T]): Complex[T] =
  ## Returns the tangent of `z`.
  result = sin(z) / cos(z)

func arctan*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse tangent of `z`.
  result = T(0.5)*im(T) * (ln(T(1.0) - im(T)*z) - ln(T(1.0) + im(T)*z))

func cot*[T](z: Complex[T]): Complex[T] =
  ## Returns the cotangent of `z`.
  result = cos(z)/sin(z)

func arccot*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse cotangent of `z`.
  result = T(0.5)*im(T) * (ln(T(1.0) - im(T)/z) - ln(T(1.0) + im(T)/z))

func sec*[T](z: Complex[T]): Complex[T] =
  ## Returns the secant of `z`.
  result = T(1.0) / cos(z)

func arcsec*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse secant of `z`.
  result = -im(T) * ln(im(T) * sqrt(1.0 - 1.0/(z*z)) + T(1.0)/z)

func csc*[T](z: Complex[T]): Complex[T] =
  ## Returns the cosecant of `z`.
  result = T(1.0) / sin(z)

func arccsc*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse cosecant of `z`.
  result = -im(T) * ln(sqrt(T(1.0) - T(1.0)/(z*z)) + im(T)/z)

func sinh*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic sine of `z`.
  result = T(0.5) * (exp(z) - exp(-z))

func arcsinh*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic sine of `z`.
  result = ln(z + sqrt(z*z + 1.0))

func cosh*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic cosine of `z`.
  result = T(0.5) * (exp(z) + exp(-z))

func arccosh*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic cosine of `z`.
  result = ln(z + sqrt(z*z - T(1.0)))

func tanh*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic tangent of `z`.
  result = sinh(z) / cosh(z)

func arctanh*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic tangent of `z`.
  result = T(0.5) * (ln((T(1.0)+z) / (T(1.0)-z)))

func coth*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic cotangent of `z`.
  result = cosh(z) / sinh(z)

func arccoth*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic cotangent of `z`.
  result = T(0.5) * (ln(T(1.0) + T(1.0)/z) - ln(T(1.0) - T(1.0)/z))

func sech*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic secant of `z`.
  result = T(2.0) / (exp(z) + exp(-z))

func arcsech*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic secant of `z`.
  result = ln(1.0/z + sqrt(T(1.0)/z+T(1.0)) * sqrt(T(1.0)/z-T(1.0)))

func csch*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic cosecant of `z`.
  result = T(2.0) / (exp(z) - exp(-z))

func arccsch*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic cosecant of `z`.
  result = ln(T(1.0)/z + sqrt(T(1.0)/(z*z) + T(1.0)))

func phase*[T](z: Complex[T]): T =
  ## Returns the phase (or argument) of `z`, that is the angle in polar representation.
  ##
  ## | `result = arctan2(z.im, z.re)`
  arctan2(z.im, z.re)

func polar*[T](z: Complex[T]): tuple[r, phi: T] =
  ## Returns `z` in polar coordinates.
  ##
  ## | `result.r = abs(z)`
  ## | `result.phi = phase(z)`
  ##
  ## **See also:**
  ## * `rect func<#rect,T,T>`_ for the inverse operation
  (r: abs(z), phi: phase(z))

func rect*[T](r, phi: T): Complex[T] =
  ## Returns the complex number with polar coordinates `r` and `phi`.
  ##
  ## | `result.re = r * cos(phi)`
  ## | `result.im = r * sin(phi)`
  ##
  ## **See also:**
  ## * `polar func<#polar,Complex[T]>`_ for the inverse operation
  complex(r * cos(phi), r * sin(phi))


func `$`*(z: Complex): string =
  ## Returns `z`'s string representation as `"(re, im)"`.
  runnableExamples:
    doAssert $complex(1.0, 2.0) == "(1.0, 2.0)"

  result = "(" & $z.re & ", " & $z.im & ")"

{.pop.}
