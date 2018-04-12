discard """
  output: "(M: 3, N: 3, fp: ...)"
"""

# bug #6843

type
  OrderType = enum colMajor, rowMajor
  Matrix[A] = object
    M, N: int
    fp: ptr A # float pointer
  DoubleArray64[M, N: static[int]] = array[M, array[N, float64]]


proc stackMatrix[M, N: static[int]](a: var DoubleArray64[M, N], order = colMajor): Matrix[float64] =
  Matrix[float64](
    fp: addr a[0][0],
    M: (if order == colMajor: N else: M),
    N: (if order == colMajor: M else: N)
  )

var
  data = [
    [1'f64, 2, 3],
    [4'f64, 5, 6],
    [7'f64, 8, 9]
  ]
  m = stackMatrix(data)
echo m