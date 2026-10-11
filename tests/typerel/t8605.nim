# bug #8605: a generic tuple instance used twice in a signature
type
  Complex[A: SomeNumber] = tuple[re, im: A]
  Complex64 = Complex[float64]

proc scal(N: int, ALPHA: Complex64, X: ptr Complex64, INCX: int): float =
  ALPHA.re + X[].im

var
  k = (re: 2.0, im: 1.0)
  v: array[2, Complex64] = [(re: 2.0, im: 1.0), (re: 3.0, im: 2.0)]

doAssert scal(2, k, addr v[0], 1) == 3.0
