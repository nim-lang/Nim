discard """
  output: '''0.0
0.0
0
0
0
'''
"""

include compilehelpers

type
  Matrix*[M, N, T] = object
    aij*: array[M, array[N, T]]

  Matrix2*[T] = Matrix[range[0..1], range[0..1], T]

  Matrix3*[T] = Matrix[range[0..2], range[0..2], T]

proc mn(x: Matrix): Matrix.T = x.aij[0][0]

proc m2(x: Matrix2): Matrix2.T = x.aij[0][0]

proc m3(x: Matrix3): auto = x.aij[0][0]

var
  matn: Matrix[range[0..3], range[0..2], int]
  mat2: Matrix2[int]
  mat3: Matrix3[float]

echo m3(mat3)
echo mn(mat3)
echo m2(mat2)
echo mn(mat2)
echo mn(matn)

reject m3(mat2)
reject m3(matn)
reject m2(mat3)
reject m2(matn)

