#
#
#            Nim's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements complex numbers.
## Complex numbers are currently implemented as generic on a 64-bit or 32-bit float.

{.push checks: off, line_dir: off, stack_trace: off, debugger: off.}
# the user does not want to trace a part of the standard library!

import math

type
  Complex*[T: SomeFloat] = object
    re*, im*: T
    ## A complex number, consisting of a real and an imaginary part.
  Complex64* = Complex[float64]
    ## Alias for a pair of 64-bit floats.
  Complex32* = Complex[float32]
    ## Alias for a pair of 32-bit floats.

proc complex*[T: SomeFloat](re: T; im: T = 0.0): Complex[T] =
  result.re = re
  result.im = im

proc complex32*(re: float32; im: float32 = 0.0): Complex[float32] =
  result.re = re
  result.im = im

proc complex64*(re: float64; im: float64 = 0.0): Complex[float64] =
  result.re = re
  result.im = im

template im*(arg: typedesc[float32]): Complex32 = complex[float32](0, 1)
template im*(arg: typedesc[float64]): Complex64 = complex[float64](0, 1)
template im*(arg: float32): Complex32 = complex[float32](0, arg)
template im*(arg: float64): Complex64 = complex[float64](0, arg)

proc abs*[T](z: Complex[T]): T =
  ## Return the distance from (0,0) to ``z``.
  result = hypot(z.re, z.im)

proc abs2*[T](z: Complex[T]): T =
  ## Return the squared distance from (0,0) to ``z``.
  result = z.re*z.re + z.im*z.im

proc conjugate*[T](z: Complex[T]): Complex[T] =
  ## Conjugate of complex number ``z``.
  result.re = z.re
  result.im = -z.im

proc inv*[T](z: Complex[T]): Complex[T] =
  ## Multiplicative inverse of complex number ``z``.
  conjugate(z) / abs2(z)

proc `==` *[T](x, y: Complex[T]): bool =
  ## Compare two complex numbers ``x`` and ``y`` for equality.
  result = x.re == y.re and x.im == y.im

proc `+` *[T](x: T; y: Complex[T]): Complex[T] =
  ## Add a real number to a complex number.
  result.re = x + y.re
  result.im = y.im

proc `+` *[T](x: Complex[T]; y: T): Complex[T] =
  ## Add a complex number to a real number.
  result.re = x.re + y
  result.im = x.im

proc `+` *[T](x, y: Complex[T]): Complex[T] =
  ## Add two complex numbers.
  result.re = x.re + y.re
  result.im = x.im + y.im

proc `-` *[T](z: Complex[T]): Complex[T] =
  ## Unary minus for complex numbers.
  result.re = -z.re
  result.im = -z.im

proc `-` *[T](x: T; y: Complex[T]): Complex[T] =
  ## Subtract a complex number from a real number.
  x + (-y)

proc `-` *[T](x: Complex[T]; y: T): Complex[T] =
  ## Subtract a real number from a complex number.
  result.re = x.re - y
  result.im = x.im

proc `-` *[T](x, y: Complex[T]): Complex[T] =
  ## Subtract two complex numbers.
  result.re = x.re - y.re
  result.im = x.im - y.im

proc `/` *[T](x: Complex[T]; y: T): Complex[T] =
  ## Divide complex number ``x`` by real number ``y``.
  result.re = x.re / y
  result.im = x.im / y

proc `/` *[T](x: T; y: Complex[T]): Complex[T] =
  ## Divide real number ``x`` by complex number ``y``.
  result = x * inv(y)

proc `/` *[T](x, y: Complex[T]): Complex[T] =
  ## Divide ``x`` by ``y``.
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

proc `*` *[T](x: T; y: Complex[T]): Complex[T] =
  ## Multiply a real number and a complex number.
  result.re = x * y.re
  result.im = x * y.im

proc `*` *[T](x: Complex[T]; y: T): Complex[T] =
  ## Multiply a complex number with a real number.
  result.re = x.re * y
  result.im = x.im * y

proc `*` *[T](x, y: Complex[T]): Complex[T] =
  ## Multiply ``x`` with ``y``.
  result.re = x.re * y.re - x.im * y.im
  result.im = x.im * y.re + x.re * y.im


proc `+=` *[T](x: var Complex[T]; y: Complex[T]) =
  ## Add ``y`` to ``x``.
  x.re += y.re
  x.im += y.im

proc `-=` *[T](x: var Complex[T]; y: Complex[T]) =
  ## Subtract ``y`` from ``x``.
  x.re -= y.re
  x.im -= y.im

proc `*=` *[T](x: var Complex[T]; y: Complex[T]) =
  ## Multiply ``y`` to ``x``.
  let im = x.im * y.re + x.re * y.im
  x.re = x.re * y.re - x.im * y.im
  x.im = im

proc `/=` *[T](x: var Complex[T]; y: Complex[T]) =
  ## Divide ``x`` by ``y`` in place.
  x = x / y


proc sqrt*[T](z: Complex[T]): Complex[T] =
  ## Square root for a complex number ``z``.
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

proc exp*[T](z: Complex[T]): Complex[T] =
  ## ``e`` raised to the power ``z``.
  var
    rho = exp(z.re)
    theta = z.im
  result.re = rho * cos(theta)
  result.im = rho * sin(theta)

proc ln*[T](z: Complex[T]): Complex[T] =
  ## Returns the natural log of ``z``.
  result.re = ln(abs(z))
  result.im = arctan2(z.im, z.re)

proc log10*[T](z: Complex[T]): Complex[T] =
  ## Returns the log base 10 of ``z``.
  result = ln(z) / ln(10.0)

proc log2*[T](z: Complex[T]): Complex[T] =
  ## Returns the log base 2 of ``z``.
  result = ln(z) / ln(2.0)

proc pow*[T](x, y: Complex[T]): Complex[T] =
  ## ``x`` raised to the power ``y``.
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
    var
      rho = abs(x)
      theta = arctan2(x.im, x.re)
      s = pow(rho, y.re) * exp(-y.im * theta)
      r = y.re * theta + y.im * ln(rho)
    result.re = s * cos(r)
    result.im = s * sin(r)

proc pow*[T](x: Complex[T]; y: T): Complex[T] =
  ## Complex number ``x`` raised to the power ``y``.
  pow(x, complex[T](y))


proc sin*[T](z: Complex[T]): Complex[T] =
  ## Returns the sine of ``z``.
  result.re = sin(z.re) * cosh(z.im)
  result.im = cos(z.re) * sinh(z.im)

proc arcsin*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse sine of ``z``.
  result = -im(T) * ln(im(T) * z + sqrt(T(1.0) - z*z))

proc cos*[T](z: Complex[T]): Complex[T] =
  ## Returns the cosine of ``z``.
  result.re = cos(z.re) * cosh(z.im)
  result.im = -sin(z.re) * sinh(z.im)

proc arccos*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse cosine of ``z``.
  result = -im(T) * ln(z + sqrt(z*z - T(1.0)))

proc tan*[T](z: Complex[T]): Complex[T] =
  ## Returns the tangent of ``z``.
  result = sin(z) / cos(z)

proc arctan*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse tangent of ``z``.
  result = T(0.5)*im(T) * (ln(T(1.0) - im(T)*z) - ln(T(1.0) + im(T)*z))

proc cot*[T](z: Complex[T]): Complex[T] =
  ## Returns the cotangent of ``z``.
  result = cos(z)/sin(z)

proc arccot*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse cotangent of ``z``.
  result = T(0.5)*im(T) * (ln(T(1.0) - im(T)/z) - ln(T(1.0) + im(T)/z))

proc sec*[T](z: Complex[T]): Complex[T] =
  ## Returns the secant of ``z``.
  result = T(1.0) / cos(z)

proc arcsec*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse secant of ``z``.
  result = -im(T) * ln(im(T) * sqrt(1.0 - 1.0/(z*z)) + T(1.0)/z)

proc csc*[T](z: Complex[T]): Complex[T] =
  ## Returns the cosecant of ``z``.
  result = T(1.0) / sin(z)

proc arccsc*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse cosecant of ``z``.
  result = -im(T) * ln(sqrt(T(1.0) - T(1.0)/(z*z)) + im(T)/z)

proc sinh*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic sine of ``z``.
  result = T(0.5) * (exp(z) - exp(-z))

proc arcsinh*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic sine of ``z``.
  result = ln(z + sqrt(z*z + 1.0))

proc cosh*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic cosine of ``z``.
  result = T(0.5) * (exp(z) + exp(-z))

proc arccosh*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic cosine of ``z``.
  result = ln(z + sqrt(z*z - T(1.0)))

proc tanh*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic tangent of ``z``.
  result = sinh(z) / cosh(z)

proc arctanh*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic tangent of ``z``.
  result = T(0.5) * (ln((T(1.0)+z) / (T(1.0)-z)))

proc sech*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic secant of ``z``.
  result = T(2.0) / (exp(z) + exp(-z))

proc arcsech*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic secant of ``z``.
  result = ln(1.0/z + sqrt(T(1.0)/z+T(1.0)) * sqrt(T(1.0)/z-T(1.0)))

proc csch*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic cosecant of ``z``.
  result = T(2.0) / (exp(z) - exp(-z))

proc arccsch*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic cosecant of ``z``.
  result = ln(T(1.0)/z + sqrt(T(1.0)/(z*z) + T(1.0)))

proc coth*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic cotangent of ``z``.
  result = cosh(z) / sinh(z)

proc arccoth*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic cotangent of ``z``.
  result = T(0.5) * (ln(T(1.0) + T(1.0)/z) - ln(T(1.0) - T(1.0)/z))

proc phase*[T](z: Complex[T]): T =
  ## Returns the phase of ``z``.
  arctan2(z.im, z.re)

proc polar*[T](z: Complex[T]): tuple[r, phi: T] =
  ## Returns ``z`` in polar coordinates.
  (r: abs(z), phi: phase(z))

proc rect*[T](r, phi: T): Complex[T] =
  ## Returns the complex number with polar coordinates ``r`` and ``phi``.
  ##
  ## | ``result.re = r * cos(phi)``
  ## | ``result.im = r * sin(phi)``
  complex(r * cos(phi), r * sin(phi))


proc `$`*(z: Complex): string =
  ## Returns ``z``'s string representation as ``"(re, im)"``.
  result = "(" & $z.re & ", " & $z.im & ")"

{.pop.}


when isMainModule:
  proc `=~`[T](x, y: Complex[T]): bool =
    result = abs(x.re-y.re) < 1e-6 and abs(x.im-y.im) < 1e-6

  proc `=~`[T](x: Complex[T]; y: T): bool =
    result = abs(x.re-y) < 1e-6 and abs(x.im) < 1e-6

  var
    z: Complex64 = complex(0.0, 0.0)
    oo: Complex64 = complex(1.0, 1.0)
    a: Complex64 = complex(1.0, 2.0)
    b: Complex64 = complex(-1.0, -2.0)
    m1: Complex64 = complex(-1.0, 0.0)
    i: Complex64 = complex(0.0, 1.0)
    one: Complex64 = complex(1.0, 0.0)
    tt: Complex64 = complex(10.0, 20.0)
    ipi: Complex64 = complex(0.0, -PI)

  doAssert(a/2.0 =~ complex(0.5, 1.0))
  doAssert(a == a)
  doAssert((a-a) == z)
  doAssert((a+b) == z)
  doAssert((a+b) =~ 0.0)
  doAssert((a/b) == m1)
  doAssert((1.0/a) =~ complex(0.2, -0.4))
  doAssert((a*b) == complex(3.0, -4.0))
  doAssert(10.0*a == tt)
  doAssert(a*10.0 == tt)
  doAssert(tt/10.0 == a)
  doAssert(oo+(-1.0) == i)
  doAssert( (-1.0)+oo == i)
  doAssert(abs(oo) == sqrt(2.0))
  doAssert(conjugate(a) == complex(1.0, -2.0))
  doAssert(sqrt(m1) == i)
  doAssert(exp(ipi) =~ m1)

  doAssert(pow(a, b) =~ complex(-3.72999124927876, -1.68815826725068))
  doAssert(pow(z, a) =~ complex(0.0, 0.0))
  doAssert(pow(z, z) =~ complex(1.0, 0.0))
  doAssert(pow(a, one) =~ a)
  doAssert(pow(a, m1) =~ complex(0.2, -0.4))
  doAssert(pow(a, 2.0) =~ complex(-3.0, 4.0))
  doAssert(pow(a, 2) =~ complex(-3.0, 4.0))
  doAssert(not(pow(a, 2.0) =~ a))

  doAssert(ln(a) =~ complex(0.804718956217050, 1.107148717794090))
  doAssert(log10(a) =~ complex(0.349485002168009, 0.480828578784234))
  doAssert(log2(a) =~ complex(1.16096404744368, 1.59727796468811))

  doAssert(sin(a) =~ complex(3.16577851321617, 1.95960104142161))
  doAssert(cos(a) =~ complex(2.03272300701967, -3.05189779915180))
  doAssert(tan(a) =~ complex(0.0338128260798967, 1.0147936161466335))
  doAssert(cot(a) =~ 1.0 / tan(a))
  doAssert(sec(a) =~ 1.0 / cos(a))
  doAssert(csc(a) =~ 1.0 / sin(a))
  doAssert(arcsin(a) =~ complex(0.427078586392476, 1.528570919480998))
  doAssert(arccos(a) =~ complex(1.14371774040242, -1.52857091948100))
  doAssert(arctan(a) =~ complex(1.338972522294494, 0.402359478108525))
  doAssert(arccot(a) =~ complex(0.2318238045004031, -0.402359478108525))
  doAssert(arcsec(a) =~ complex(1.384478272687081, 0.3965682301123288))
  doAssert(arccsc(a) =~ complex(0.1863180541078155, -0.3965682301123291))

  doAssert(cosh(a) =~ complex(-0.642148124715520, 1.068607421382778))
  doAssert(sinh(a) =~ complex(-0.489056259041294, 1.403119250622040))
  doAssert(tanh(a) =~ complex(1.1667362572409199, -0.243458201185725))
  doAssert(sech(a) =~ 1.0 / cosh(a))
  doAssert(csch(a) =~ 1.0 / sinh(a))
  doAssert(coth(a) =~ 1.0 / tanh(a))
  doAssert(arccosh(a) =~ complex(1.528570919480998, 1.14371774040242))
  doAssert(arcsinh(a) =~ complex(1.469351744368185, 1.06344002357775))
  doAssert(arctanh(a) =~ complex(0.173286795139986, 1.17809724509617))
  doAssert(arcsech(a) =~ arccosh(1.0/a))
  doAssert(arccsch(a) =~ arcsinh(1.0/a))
  doAssert(arccoth(a) =~ arctanh(1.0/a))

  doAssert(phase(a) == 1.1071487177940904)
  var t = polar(a)
  doAssert(rect(t.r, t.phi) =~ a)
  doAssert(rect(1.0, 2.0) =~ complex(-0.4161468365471424, 0.9092974268256817))


  var
    i64: Complex32 = complex(0.0f, 1.0f)
    a64: Complex32 = 2.0f*i64 + 1.0.float32
    b64: Complex32 = complex(-1.0'f32, -2.0'f32)

  doAssert(a64 == a64)
  doAssert(a64 == -b64)
  doAssert(a64 + b64 =~ 0.0'f32)
  doAssert(not(pow(a64, b64) =~ a64))
  doAssert(pow(a64, 0.5f) =~ sqrt(a64))
  doAssert(pow(a64, 2) =~ complex(-3.0'f32, 4.0'f32))
  doAssert(sin(arcsin(b64)) =~ b64)
  doAssert(cosh(arccosh(a64)) =~ a64)

  doAssert(phase(a64) - 1.107149f < 1e-6)
  var t64 = polar(a64)
  doAssert(rect(t64.r, t64.phi) =~ a64)
  doAssert(rect(1.0f, 2.0f) =~ complex(-0.4161468f, 0.90929742f))
  doAssert(sizeof(a64) == 8)
  doAssert(sizeof(a) == 16)

  doAssert 123.0.im + 456.0 == complex64(456, 123)

  var localA = complex(0.1'f32)
  doAssert localA.im is float32
