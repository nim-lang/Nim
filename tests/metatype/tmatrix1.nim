discard """
  output: "right proc called"
"""

type
  TMatrixNM*[M, N, T] = object
    aij*: array[M, array[N, T]]
  TMatrix2x2*[T] = TMatrixNM[range[0..1], range[0..1], T]
  TMatrix3x3*[T] = TMatrixNM[range[0..2], range[0..2], T]

proc test*[T](matrix: TMatrix2x2[T]) =
  echo "wrong proc called"

proc test*[T](matrix: TMatrix3x3[T]) =
  echo "right proc called"

var matrix: TMatrix3x3[float]

matrix.test
