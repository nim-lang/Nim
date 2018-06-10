#
#
#            Nim's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#



## This module implements complex numbers.
{.push checks:off, line_dir:off, stack_trace:off, debugger:off.}
# the user does not want to trace a part
# of the standard library!


import
  math

const
  EPS = 1.0e-7 ## Epsilon used for float comparisons.

type
  Complex* = tuple[re, im: float]
    ## a complex number, consisting of a real and an imaginary part

const
  im*: Complex = (re: 0.0, im: 1.0)
    ## The imaginary unit. √-1.

proc toComplex*(x: SomeInteger): Complex =
  ## Convert some integer ``x`` to a complex number.
  result.re = x
  result.im = 0

proc `==` *(x, y: Complex): bool =
  ## Compare two complex numbers `x` and `y` for equality.
  result = x.re == y.re and x.im == y.im

proc `=~` *(x, y: Complex): bool =
  ## Compare two complex numbers `x` and `y` approximately.
  result = abs(x.re-y.re)<EPS and abs(x.im-y.im)<EPS

proc `+` *(x, y: Complex): Complex =
  ## Add two complex numbers.
  result.re = x.re + y.re
  result.im = x.im + y.im

proc `+` *(x: Complex, y: float): Complex =
  ## Add complex `x` to float `y`.
  result.re = x.re + y
  result.im = x.im

proc `+` *(x: float, y: Complex): Complex =
  ## Add float `x` to complex `y`.
  result.re = x + y.re
  result.im = y.im


proc `-` *(z: Complex): Complex =
  ## Unary minus for complex numbers.
  result.re = -z.re
  result.im = -z.im

proc `-` *(x, y: Complex): Complex =
  ## Subtract two complex numbers.
  result.re = x.re - y.re
  result.im = x.im - y.im

proc `-` *(x: Complex, y: float): Complex =
  ## Subtracts float `y` from complex `x`.
  result = x + (-y)

proc `-` *(x: float, y: Complex): Complex =
  ## Subtracts complex `y` from float `x`.
  result = x + (-y)


proc `/` *(x, y: Complex): Complex =
  ## Divide `x` by `y`.
  var
    r, den: float
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

proc `/` *(x : Complex, y: float ): Complex =
  ## Divide complex `x` by float `y`.
  result.re = x.re/y
  result.im = x.im/y

proc `/` *(x : float, y: Complex ): Complex =
  ## Divide float `x` by complex `y`.
  var num : Complex = (x, 0.0)
  result = num/y


proc `*` *(x, y: Complex): Complex =
  ## Multiply `x` with `y`.
  result.re = x.re * y.re - x.im * y.im
  result.im = x.im * y.re + x.re * y.im

proc `*` *(x: float, y: Complex): Complex =
  ## Multiply float `x` with complex `y`.
  result.re = x * y.re
  result.im = x * y.im

proc `*` *(x: Complex, y: float): Complex =
  ## Multiply complex `x` with float `y`.
  result.re = x.re * y
  result.im = x.im * y


proc `+=` *(x: var Complex, y: Complex) =
  ## Add `y` to `x`.
  x.re += y.re
  x.im += y.im

proc `+=` *(x: var Complex, y: float) =
  ## Add `y` to the complex number `x`.
  x.re += y

proc `-=` *(x: var Complex, y: Complex) =
  ## Subtract `y` from `x`.
  x.re -= y.re
  x.im -= y.im

proc `-=` *(x: var Complex, y: float) =
  ## Subtract `y` from the complex number `x`.
  x.re -= y

proc `*=` *(x: var Complex, y: Complex) =
  ## Multiply `y` to `x`.
  let im = x.im * y.re + x.re * y.im
  x.re = x.re * y.re - x.im * y.im
  x.im = im

proc `*=` *(x: var Complex, y: float) =
  ## Multiply `y` to the complex number `x`.
  x.re *= y
  x.im *= y

proc `/=` *(x: var Complex, y: Complex) =
  ## Divide `x` by `y` in place.
  x = x / y

proc `/=` *(x : var Complex, y: float) =
  ## Divide complex `x` by float `y` in place.
  x.re /= y
  x.im /= y


proc abs*(z: Complex): float =
  ## Return the distance from (0,0) to `z`.

  # optimized by checking special cases (sqrt is expensive)
  var x, y, temp: float

  x = abs(z.re)
  y = abs(z.im)
  if x == 0.0:
    result = y
  elif y == 0.0:
    result = x
  elif x > y:
    temp = y / x
    result = x * sqrt(1.0 + temp * temp)
  else:
    temp = x / y
    result = y * sqrt(1.0 + temp * temp)


proc conjugate*(z: Complex): Complex =
  ## Conjugate of complex number `z`.
  result.re = z.re
  result.im = -z.im


proc sqrt*(z: Complex): Complex =
  ## Square root for a complex number `z`.
  var x, y, w, r: float

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
      if z.im >= 0.0: result.im = w
      else:           result.im = -w
      result.re = z.im / (result.im + result.im)


proc exp*(z: Complex): Complex =
  ## e raised to the power `z`.
  var rho   = exp(z.re)
  var theta = z.im
  result.re = rho*cos(theta)
  result.im = rho*sin(theta)


proc ln*(z: Complex): Complex =
  ## Returns the natural log of `z`.
  result.re = ln(abs(z))
  result.im = arctan2(z.im,z.re)

proc log10*(z: Complex): Complex =
  ## Returns the log base 10 of `z`.
  result = ln(z)/ln(10.0)

proc log2*(z: Complex): Complex =
  ## Returns the log base 2 of `z`.
  result = ln(z)/ln(2.0)


proc pow*(x, y: Complex): Complex =
  ## `x` raised to the power `y`.
  if x.re == 0.0  and  x.im == 0.0:
    if y.re == 0.0  and  y.im == 0.0:
      result.re = 1.0
      result.im = 0.0
    else:
      result.re = 0.0
      result.im = 0.0
  elif y.re == 1.0  and  y.im == 0.0:
    result = x
  elif y.re == -1.0  and  y.im == 0.0:
    result = 1.0/x
  else:
    var rho   = sqrt(x.re*x.re + x.im*x.im)
    var theta = arctan2(x.im,x.re)
    var s     = pow(rho,y.re) * exp(-y.im*theta)
    var r     = y.re*theta + y.im*ln(rho)
    result.re = s*cos(r)
    result.im = s*sin(r)


proc sin*(z: Complex): Complex =
  ## Returns the sine of `z`.
  result.re = sin(z.re)*cosh(z.im)
  result.im = cos(z.re)*sinh(z.im)

proc arcsin*(z: Complex): Complex =
  ## Returns the inverse sine of `z`.
  var i: Complex = (0.0,1.0)
  result = -i*ln(i*z + sqrt(1.0-z*z))

proc cos*(z: Complex): Complex =
  ## Returns the cosine of `z`.
  result.re = cos(z.re)*cosh(z.im)
  result.im = -sin(z.re)*sinh(z.im)

proc arccos*(z: Complex): Complex =
  ## Returns the inverse cosine of `z`.
  var i: Complex = (0.0,1.0)
  result = -i*ln(z + sqrt(z*z-1.0))

proc tan*(z: Complex): Complex =
  ## Returns the tangent of `z`.
  result = sin(z)/cos(z)

proc arctan*(z: Complex): Complex =
  ## Returns the inverse tangent of `z`.
  var i: Complex = (0.0,1.0)
  result = 0.5*i*(ln(1-i*z)-ln(1+i*z))

proc cot*(z: Complex): Complex =
  ## Returns the cotangent of `z`.
  result = cos(z)/sin(z)

proc arccot*(z: Complex): Complex =
  ## Returns the inverse cotangent of `z`.
  var i: Complex = (0.0,1.0)
  result = 0.5*i*(ln(1-i/z)-ln(1+i/z))

proc sec*(z: Complex): Complex =
  ## Returns the secant of `z`.
  result = 1.0/cos(z)

proc arcsec*(z: Complex): Complex =
  ## Returns the inverse secant of `z`.
  var i: Complex = (0.0,1.0)
  result = -i*ln(i*sqrt(1-1/(z*z))+1/z)

proc csc*(z: Complex): Complex =
  ## Returns the cosecant of `z`.
  result = 1.0/sin(z)

proc arccsc*(z: Complex): Complex =
  ## Returns the inverse cosecant of `z`.
  var i: Complex = (0.0,1.0)
  result = -i*ln(sqrt(1-1/(z*z))+i/z)


proc sinh*(z: Complex): Complex =
  ## Returns the hyperbolic sine of `z`.
  result = 0.5*(exp(z)-exp(-z))

proc arcsinh*(z: Complex): Complex =
  ## Returns the inverse hyperbolic sine of `z`.
  result = ln(z+sqrt(z*z+1))

proc cosh*(z: Complex): Complex =
  ## Returns the hyperbolic cosine of `z`.
  result = 0.5*(exp(z)+exp(-z))

proc arccosh*(z: Complex): Complex =
  ## Returns the inverse hyperbolic cosine of `z`.
  result = ln(z+sqrt(z*z-1))

proc tanh*(z: Complex): Complex =
  ## Returns the hyperbolic tangent of `z`.
  result = sinh(z)/cosh(z)

proc arctanh*(z: Complex): Complex =
  ## Returns the inverse hyperbolic tangent of `z`.
  result = 0.5*(ln((1+z)/(1-z)))

proc sech*(z: Complex): Complex =
  ## Returns the hyperbolic secant of `z`.
  result = 2/(exp(z)+exp(-z))

proc arcsech*(z: Complex): Complex =
  ## Returns the inverse hyperbolic secant of `z`.
  result = ln(1/z+sqrt(1/z+1)*sqrt(1/z-1))

proc csch*(z: Complex): Complex =
  ## Returns the hyperbolic cosecant of `z`.
  result = 2/(exp(z)-exp(-z))

proc arccsch*(z: Complex): Complex =
  ## Returns the inverse hyperbolic cosecant of `z`.
  result = ln(1/z+sqrt(1/(z*z)+1))

proc coth*(z: Complex): Complex =
  ## Returns the hyperbolic cotangent of `z`.
  result = cosh(z)/sinh(z)

proc arccoth*(z: Complex): Complex =
  ## Returns the inverse hyperbolic cotangent of `z`.
  result = 0.5*(ln(1+1/z)-ln(1-1/z))

proc phase*(z: Complex): float =
  ## Returns the phase of `z`.
  arctan2(z.im, z.re)

proc polar*(z: Complex): tuple[r, phi: float] =
  ## Returns `z` in polar coordinates.
  result.r = abs(z)
  result.phi = phase(z)

proc rect*(r: float, phi: float): Complex =
  ## Returns the complex number with polar coordinates `r` and `phi`.
  result.re = r * cos(phi)
  result.im = r * sin(phi)


proc `$`*(z: Complex): string =
  ## Returns `z`'s string representation as ``"(re, im)"``.
  result = "(" & $z.re & ", " & $z.im & ")"

{.pop.}


when isMainModule:
  var z = (0.0, 0.0)
  var oo = (1.0,1.0)
  var a = (1.0, 2.0)
  var b = (-1.0, -2.0)
  var m1 = (-1.0, 0.0)
  var i = (0.0,1.0)
  var one = (1.0,0.0)
  var tt = (10.0, 20.0)
  var ipi = (0.0, -PI)

  assert( a == a )
  assert( (a-a) == z )
  assert( (a+b) == z )
  assert( (a/b) == m1 )
  assert( (1.0/a) == (0.2, -0.4) )
  assert( (a*b) == (3.0, -4.0) )
  assert( 10.0*a == tt )
  assert( a*10.0 == tt )
  assert( tt/10.0 == a )
  assert( oo+(-1.0) == i )
  assert( (-1.0)+oo == i )
  assert( abs(oo) == sqrt(2.0) )
  assert( conjugate(a) == (1.0, -2.0) )
  assert( sqrt(m1) == i )
  assert( exp(ipi) =~ m1 )

  assert( pow(a,b) =~ (-3.72999124927876, -1.68815826725068) )
  assert( pow(z,a) =~ (0.0, 0.0) )
  assert( pow(z,z) =~ (1.0, 0.0) )
  assert( pow(a,one) =~ a )
  assert( pow(a,m1) =~ (0.2, -0.4) )

  assert( ln(a) =~ (0.804718956217050, 1.107148717794090) )
  assert( log10(a) =~ (0.349485002168009, 0.480828578784234) )
  assert( log2(a) =~ (1.16096404744368, 1.59727796468811) )

  assert( sin(a) =~ (3.16577851321617, 1.95960104142161) )
  assert( cos(a) =~ (2.03272300701967, -3.05189779915180) )
  assert( tan(a) =~ (0.0338128260798967, 1.0147936161466335) )
  assert( cot(a) =~ 1.0/tan(a) )
  assert( sec(a) =~ 1.0/cos(a) )
  assert( csc(a) =~ 1.0/sin(a) )
  assert( arcsin(a) =~ (0.427078586392476, 1.528570919480998) )
  assert( arccos(a) =~ (1.14371774040242, -1.52857091948100) )
  assert( arctan(a) =~ (1.338972522294494, 0.402359478108525) )

  assert( cosh(a) =~ (-0.642148124715520, 1.068607421382778) )
  assert( sinh(a) =~ (-0.489056259041294, 1.403119250622040) )
  assert( tanh(a) =~ (1.1667362572409199,-0.243458201185725) )
  assert( sech(a) =~ 1/cosh(a) )
  assert( csch(a) =~ 1/sinh(a) )
  assert( coth(a) =~ 1/tanh(a) )
  assert( arccosh(a) =~ (1.528570919480998, 1.14371774040242) )
  assert( arcsinh(a) =~ (1.469351744368185, 1.06344002357775) )
  assert( arctanh(a) =~ (0.173286795139986, 1.17809724509617) )
  assert( arcsech(a) =~ arccosh(1/a) )
  assert( arccsch(a) =~ arcsinh(1/a) )
  assert( arccoth(a) =~ arctanh(1/a) )

  assert( phase(a) == 1.1071487177940904 )
  var t = polar(a)
  assert( rect(t.r, t.phi) =~ a )
  assert( rect(1.0, 2.0) =~ (-0.4161468365471424, 0.9092974268256817) )
