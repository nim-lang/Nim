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
