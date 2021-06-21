template reject(e) =
  static: assert(not compiles(e))

type
  TMatrix[T; M, N: static[int]] = array[M*N, T]

proc `*`[T; R, N, C](a: TMatrix[T, R, N], b: TMatrix[T, N, C]): TMatrix[T, R, C] =
  discard

var m1: TMatrix[int, 6, 4]
var m2: TMatrix[int, 4, 3]
var m3: TMatrix[int, 3, 3]

var m4 = m1*m2
static: assert m4.M == 6 and m4.N == 3

reject m1 * m3 # not compatible

var m5 = m2 * m3
static: assert high(m5) == 11 # 4*3 - 1

