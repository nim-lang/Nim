# bug #3799

import macros

const nmax = 500

type
  Complex*[T] = object
    re*: T
    im*: T

converter toComplex*[T](x: tuple[re, im: T]): Complex[T] =
  result.re = x.re
  result.im = x.im


proc julia*[T](z0, c: Complex[T], er2: T, nmax: int): int =
  result = 0
  var z = z0
  var sre = z0.re * z0.re
  var sim = z0.im * z0.im
  while (result < nmax) and (sre + sim < er2):
    z.im = z.re * z.im
    z.im = z.im + z.im
    z.im = z.im + c.im
    z.re = sre - sim + c.re
    sre = z.re * z.re
    sim = z.im * z.im
    inc result

template dendriteFractal*[T](z0: Complex[T], er2: T, nmax: int): int =
  julia(z0, (T(0.0), T(1.0)), er2, nmax)

iterator stepIt[T](start, step: T, iterations: int): T =
  for i in 0 .. iterations:
    yield start + T(i) * step


let c = (0.36237, 0.32)
for y in stepIt(2.0, -0.0375, 107):
  var row = ""
  for x in stepIt(-2.0, 0.025, 160):
    #let n = julia((x, y), c, 4.0, nmax)         ### this works
    let n = dendriteFractal((x, y), 4.0, nmax)
    if n < nmax:
      row.add($(n mod 10))
    else:
      row.add(' ')
  echo row
