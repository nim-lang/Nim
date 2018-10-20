
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
##
## Converters are defined to implicitly convert ordinary numbers and complex
## types into complex types. This works normally for 128-bit complex numbers but
## due to type conversion being non-transitive, dividing integer literals by
## 64-bit complex numbers and vice versa can cause compilation errors

{.push checks: off, line_dir: off, stack_trace: off, debugger: off.}
# the user does not want to trace a part of the standard library!


import math

type
  Complex*[T] = tuple[re, im: T]
    ## A complex number, consisting of a real and an imaginary part.
  Complex128* = Complex[float64]
    ## Alias for a pair of 64-bit floats.
  Complex64* = Complex[float32]
    ## Alias for a pair of 64-bit floats.


const
  im*: Complex128 = (re: 0.0, im: 1.0)
    ## The imaginary unit. √-1.


converter toComplex128*[T: SomeInteger | float64](x: T): Complex128 =
  ## Convert some number ``x`` to a 128-bit complex number.
  result.re = x.float64
  result.im = 0

converter toComplex128*[T: Complex](z: T): Complex128 =
  ## Convert some complex number ``z`` to a 128-bit complex number.
  let (re, im) = z
  result.re = re.float64
  result.im = im.float64

converter toComplex64*[T: SomeInteger | float32](x: T): Complex64 =
  ## Convert some number ``x`` to a 64-bit complex number.
  result.re = x.float32
  result.im = 0

converter toComplex64*[T: Complex](z: T): Complex64 =
  ## Convert some complex number ``z`` to a 64-bit complex number.
  let (re, im) = z
  result.re = re.float32
  result.im = im.float32


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

proc `=~` *[T](x, y: Complex[T]): bool =
  ## Compare two complex numbers ``x`` and ``y`` approximately.
  result = (x.re =~ y.re) and (x.im =~ y.im)

proc `!=~` *[T](x, y: Complex[T]): bool =
  ## Return true if two complex numbers ``x`` and ``y`` are not equal
  result = not (x =~ y)


proc `+` *[T](x: SomeFloat, y: Complex[T]): Complex[T] =
  ## Add a real number to a complex number
  result.re = x + y.re
  result.im = y.im

proc `+` *[T](x: Complex[T], y: SomeFloat): Complex[T] =
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

proc `-` *[T](x: SomeFloat, y: Complex[T]): Complex[T] =
  ## Subtract a complex number from a real number.
  x + (-y)

proc `-` *[T](x: Complex[T], y: SomeFloat): Complex[T] =
  ## Subtract a real number from a complex number.
  result.re = x.re - y
  result.im = x.im

proc `-` *[T](x, y: Complex[T]): Complex[T] =
  ## Subtract two complex numbers.
  result.re = x.re - y.re
  result.im = x.im - y.im

proc `/` *[T](x: Complex[T], y: SomeFloat): Complex[T] =
  ## Divide complex number ``x`` by real number ``y``.
  result.re = x.re / y
  result.im = x.im / y

proc `/` *[T](x: SomeFloat, y: Complex[T]): Complex[T] =
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

proc `*` *[T](x: SomeFloat, y: Complex[T]): Complex[T] =
  ## Add a real number to a complex number
  result.re = x * y.re
  result.im = x * y.im

proc `*` *[T](x: Complex[T], y: SomeFloat): Complex[T] =
  ## Add a complex number to a real number.
  result.re = x.re * y
  result.im = x.im * y

proc `*` *[T](x, y: Complex[T]): Complex[T] =
  ## Multiply ``x`` with ``y``.
  result.re = x.re * y.re - x.im * y.im
  result.im = x.im * y.re + x.re * y.im

proc `+=` *[T](x: var Complex[T], y: Complex[T]) =
  ## Add ``y`` to ``x``.
  x.re += y.re
  x.im += y.im

proc `-=` *[T](x: var Complex[T], y: Complex[T]) =
  ## Subtract ``y`` from ``x``.
  x.re -= y.re
  x.im -= y.im

proc `*=` *[T](x: var Complex[T], y: Complex[T]) =
  ## Multiply ``y`` to ``x``.
  let im = x.im * y.re + x.re * y.im
  x.re = x.re * y.re - x.im * y.im
  x.im = im

proc `/=` *[T](x: var Complex[T], y: Complex[T]) =
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
    result = 1.0/x
  else:
    var
      rho = abs(x)
      theta = arctan2(x.im, x.re)
      s = pow(rho, y.re) * exp(-y.im * theta)
      r = y.re * theta + y.im * ln(rho)
    result.re = s * cos(r)
    result.im = s * sin(r)

proc `**` *[T](x, y: Complex[T]): Complex[T] =
  ## Exponentiation operator: ``x`` raised to the power ``y``.
  pow(x, y)


proc sin*[T](z: Complex[T]): Complex[T] =
  ## Returns the sine of ``z``.
  result.re = sin(z.re) * cosh(z.im)
  result.im = cos(z.re) * sinh(z.im)

proc arcsin*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse sine of ``z``.
  result = -im * ln(im*z + sqrt(1.0 - z*z))

proc cos*[T](z: Complex[T]): Complex[T] =
  ## Returns the cosine of ``z``.
  result.re = cos(z.re) * cosh(z.im)
  result.im = -sin(z.re) * sinh(z.im)

proc arccos*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse cosine of ``z``.
  result = -im * ln(z + sqrt(z*z - 1.0))

proc tan*[T](z: Complex[T]): Complex[T] =
  ## Returns the tangent of ``z``.
  result = sin(z) / cos(z)

proc arctan*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse tangent of ``z``.
  result = 0.5*im * (ln(1 - im*z) - ln(1 + im*z))

proc cot*[T](z: Complex[T]): Complex[T] =
  ## Returns the cotangent of ``z``.
  result = cos(z)/sin(z)

proc arccot*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse cotangent of ``z``.
  result = 0.5*im * (ln(1 - im/z) - ln(1 + im/z))

proc sec*[T](z: Complex[T]): Complex[T] =
  ## Returns the secant of ``z``.
  result = 1.0 / cos(z)

proc arcsec*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse secant of ``z``.
  result = -im * ln(im * sqrt(1 - 1/(z*z)) + 1/z)

proc csc*[T](z: Complex[T]): Complex[T] =
  ## Returns the cosecant of ``z``.
  result = 1.0 / sin(z)

proc arccsc*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse cosecant of ``z``.
  result = -im * ln(sqrt(1 - 1/(z*z)) + im/z)


proc sinh*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic sine of ``z``.
  result = 0.5 * (exp(z) - exp(-z))

proc arcsinh*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic sine of ``z``.
  result = ln(z + sqrt(z*z + 1))

proc cosh*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic cosine of ``z``.
  result = 0.5 * (exp(z) + exp(-z))

proc arccosh*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic cosine of ``z``.
  result = ln(z + sqrt(z*z - 1.0))

proc tanh*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic tangent of ``z``.
  result = sinh(z) / cosh(z)

proc arctanh*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic tangent of ``z``.
  result = 0.5 * (ln((1.0+z) / (1.0-z)))

proc sech*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic secant of ``z``.
  result = 2.0 / (exp(z) + exp(-z))

proc arcsech*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic secant of ``z``.
  result = ln(1.0/z + sqrt(1.0/z+1.0) * sqrt(1.0/z-1.0))

proc csch*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic cosecant of ``z``.
  result = 2.0 / (exp(z) - exp(-z))

proc arccsch*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic cosecant of ``z``.
  result = ln(1.0/z + sqrt(1.0/(z*z) + 1.0))

proc coth*[T](z: Complex[T]): Complex[T] =
  ## Returns the hyperbolic cotangent of ``z``.
  result = cosh(z) / sinh(z)

proc arccoth*[T](z: Complex[T]): Complex[T] =
  ## Returns the inverse hyperbolic cotangent of ``z``.
  result = 0.5 * (ln(1.0 + 1.0/z) - ln(1.0 - 1.0/z))


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
  (re: r * cos(phi), im: r * sin(phi))


proc `$`*(z: Complex): string =
  ## Returns ``z``'s string representation as ``"(re, im)"``.
  result = "(" & $z.re & ", " & $z.im & ")"

{.pop.}


when isMainModule:
  var z: Complex128 = (0.0, 0.0)
  var oo: Complex128 = (1.0, 1.0)
  var a: Complex128 = (1.0, 2.0)
  var b: Complex128 = (-1.0, -2.0)
  var m1: Complex128 = (-1.0, 0.0)
  var i: Complex128 = (0.0, 1.0)
  var one: Complex128 = (1.0, 0.0)
  var tt: Complex128 = (10.0, 20.0)
  var ipi: Complex128 = (0.0, -PI)

  doAssert(a/2 =~ (0.5, 1.0))

  doAssert(a == a)
  doAssert((a-a) == z)
  doAssert((a+b) == z)
  doAssert((a/b) == m1)
  doAssert((1.0/a) == (0.2, -0.4))
  doAssert((a*b) == (3.0, -4.0))
  doAssert(10.0*a == tt)
  doAssert(a*10.0 == tt)
  doAssert(tt/10.0 == a)
  doAssert(oo+(-1.0) == i)
  doAssert( (-1.0)+oo == i)
  doAssert(abs(oo) == sqrt(2.0))
  doAssert(conjugate(a) == (1.0, -2.0))
  doAssert(sqrt(m1) == i)
  doAssert(exp(ipi) =~ m1)

  doAssert(pow(a, b) =~ (-3.72999124927876, -1.68815826725068))
  doAssert(pow(z, a) =~ (0.0, 0.0))
  doAssert(pow(z, z) =~ (1.0, 0.0))
  doAssert(pow(a, one) =~ a)
  doAssert(pow(a, m1) =~ (0.2, -0.4))
  doAssert(pow(a, 2) !=~ a)

  doAssert(ln(a) =~ (0.804718956217050, 1.107148717794090))
  doAssert(log10(a) =~ (0.349485002168009, 0.480828578784234))
  doAssert(log2(a) =~ (1.16096404744368, 1.59727796468811))

  doAssert(sin(a) =~ (3.16577851321617, 1.95960104142161))
  doAssert(cos(a) =~ (2.03272300701967, -3.05189779915180))
  doAssert(tan(a) =~ (0.0338128260798967, 1.0147936161466335))
  doAssert(cot(a) =~ 1.0/tan(a))
  doAssert(sec(a) =~ 1.0/cos(a))
  doAssert(csc(a) =~ 1.0/sin(a))
  doAssert(arcsin(a) =~ (0.427078586392476, 1.528570919480998))
  doAssert(arccos(a) =~ (1.14371774040242, -1.52857091948100))
  doAssert(arctan(a) =~ (1.338972522294494, 0.402359478108525))

  doAssert(cosh(a) =~ (-0.642148124715520, 1.068607421382778))
  doAssert(sinh(a) =~ (-0.489056259041294, 1.403119250622040))
  doAssert(tanh(a) =~ (1.1667362572409199, -0.243458201185725))
  doAssert(sech(a) =~ 1/cosh(a))
  doAssert(csch(a) =~ 1/sinh(a))
  doAssert(coth(a) =~ 1/tanh(a))
  doAssert(arccosh(a) =~ (1.528570919480998, 1.14371774040242))
  doAssert(arcsinh(a) =~ (1.469351744368185, 1.06344002357775))
  doAssert(arctanh(a) =~ (0.173286795139986, 1.17809724509617))
  doAssert(arcsech(a) =~ arccosh(1/a))
  doAssert(arccsch(a) =~ arcsinh(1/a))
  doAssert(arccoth(a) =~ arctanh(1/a))

  doAssert(phase(a) == 1.1071487177940904)
  var t = polar(a)
  doAssert(rect(t.r, t.phi) =~ a)
  doAssert(rect(1.0, 2.0) =~ (-0.4161468365471424, 0.9092974268256817))


  var i64: Complex64 = (0.0f, 1.0f)
  var a64: Complex64 = 2.0f*i64 + 1.0.float32
  var b64: Complex64 = (re: -1.0, im: -2.0)

  doAssert(a64 == a64)
  doAssert(a64 == -b64)
  doAssert(a64 + b64 =~ 0.0f)
  doAssert(pow(a64, b64) !=~ a64)
  doAssert(pow(a64, 0.5f) =~ sqrt(a64))
  doAssert(sin(arcsin(b64)) =~ b64)
  doAssert(cosh(arccosh(a64)) =~ a64)

  doAssert(phase(a64) =~ 1.107149f)
  var t64 = polar(a64)
  doAssert(rect(t64.r, t64.phi) =~ a64)
  doAssert(rect(1.0f, 2.0f) =~ (-0.4161468f, 0.90929742f))
  doAssert(sizeof(a64) == 8)
  doAssert(sizeof(a) == 16)
