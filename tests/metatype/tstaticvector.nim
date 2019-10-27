discard """
  output: '''0
0
2
100
30.0 [data = [2.0]]
'''
"""

type
  RectArray*[R, C: static[int], T] = distinct array[R * C, T]

  StaticMatrix*[R, C: static[int], T] = object
    elements*: RectArray[R, C, T]

  StaticVector*[N: static[int], T] = StaticMatrix[N, 1, T]

proc foo*[N, T](a: StaticVector[N, T]): T = 0.T
proc foobar*[N, T](a, b: StaticVector[N, T]): T = 0.T

var a: StaticVector[3, int]

echo foo(a) # OK
echo foobar(a, a) # <--- hangs compiler

# https://github.com/nim-lang/Nim/issues/3112

type
  Vector[N: static[int]] = array[N, float64]
  TwoVectors[Na, Nb: static[int]] = tuple
    a: Vector[Na]
    b: Vector[Nb]

var v: TwoVectors[2, 100]
echo v[0].len
echo v[1].len
#let xx = 50
v[1][50] = 0.0

# https://github.com/nim-lang/Nim/issues/1051

type
  TMatrix[N,M: static[int], T] = object
    data: array[0..M*N-1, T]

  TMat4f = TMatrix[4,4,float32]
  TVec3f = TMatrix[1,3,float32]
  TVec4f = TMatrix[1,4,float32]

  TVec[N: static[int]; T] = TMatrix[1,N,T]

proc dot*(a, b: TVec): TVec.T =
  #assert(a.data.len == b.data.len)
  for i in 1..a.data.len:
    result += a.data[i-1] * b.data[i-1]

proc row*(a: TMatrix; i: int): auto =
  result = TVec[TMatrix.M, TMatrix.T]()
  for idx in 1 .. TMatrix.M:
    result.data[idx-1] = a.data[(TMatrix.N * (idx-1)) + (i-1)]

proc col*(a: TMatrix; j: int): auto =
  result = TVec[TMatrix.N, TMatrix.T]()
  for idx in 0 ..< TMatrix.N:
    result.data[idx] = a.data[(TMatrix.N * (idx)) + (j-1)]

proc mul*(a: TMat4f; b: TMat4f): TMat4f =
  for i in 1..4:
    for j in 1..4:
      result.data[(4 * (j-1)) + (i-1)] = dot(row(a,i), col(b,j))

var test = TVec4f(data: [1.0'f32, 2.0'f32, 3.0'f32, 4.0'f32])

echo dot(test,test), " ", repr(col(test, 2))

