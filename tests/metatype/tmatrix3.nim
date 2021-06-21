discard """
  output: "\n"
"""

type Matrix[M,N: static[int]] = array[M, array[N, float]]

let a = [[1.0,  1.0,  1.0,   1.0],
         [2.0,  4.0,  8.0,  16.0],
         [3.0,  9.0, 27.0,  81.0],
         [4.0, 16.0, 64.0, 256.0]]

proc `$`(m: Matrix): string =
  result = ""

proc `*`[M,N,M2,N2](a: Matrix[M,N2]; b: Matrix[M2,N]): Matrix[M,N] =
  discard

echo a * a

