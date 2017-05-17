discard """
output: "perm: 22 det: 22"
"""

type Matrix[M,N: static[int]] = array[M, array[N, float]]

proc det[M,N](a: Matrix[M,N]): int = N*10 + M
proc perm[M,N](a: Matrix[M,N]): int = M*10 + N

const
  a = [ [1.0, 2.0]
      , [3.0, 4.0]
      ]

echo "perm: ", a.perm, " det: ", a.det

# This tests multiple instantiations of a generic
# proc involving static params:
type
  Vector64*[N: static[int]] = ref array[N, float64]
  Array64[N: static[int]] = array[N, float64]

proc vector*[N: static[int]](xs: Array64[N]): Vector64[N] =
  new result
  for i in 0 .. < N:
    result[i] = xs[i]

let v1 = vector([1.0, 2.0, 3.0, 4.0, 5.0])
let v2 = vector([1.0, 2.0, 3.0, 4.0, 5.0])
let v3 = vector([1.0, 2.0, 3.0, 4.0])

