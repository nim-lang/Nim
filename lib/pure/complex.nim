#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
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

type
  TComplex* = tuple[re, im: float] 
    ## a complex number, consisting of a real and an imaginary part

proc `==` *(x, y: TComplex): bool =
  ## Compare two complex numbers `x` and `y` for equality.
  result = x.re == y.re and x.im == y.im

proc `+` *(x, y: TComplex): TComplex =
  ## Add two complex numbers.
  result.re = x.re + y.re
  result.im = x.im + y.im

proc `-` *(x, y: TComplex): TComplex =
  ## Subtract two complex numbers.
  result.re = x.re - y.re
  result.im = x.im - y.im

proc `-` *(z: TComplex): TComplex =
  ## Unary minus for complex numbers.
  result.re = -z.re
  result.im = -z.im

proc `/` *(x, y: TComplex): TComplex =
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

proc `*` *(x, y: TComplex): TComplex =
  ## Multiply `x` with `y`.
  result.re = x.re * y.re - x.im * y.im
  result.im = x.im * y.re + x.re * y.im

proc abs*(z: TComplex): float =
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

proc sqrt*(z: TComplex): TComplex =
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
      result.re = z.im / (c.im + c.im)

{.pop.}
