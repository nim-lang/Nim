discard """
  nimout: "(Field0: 2, Field1: 2, Field2: 2, Field3: 2)"
"""

proc foo[N: static[int]](dims: array[N, int])=
  const N1 = N
  const N2 = dims.len
  static: echo (N, dims.len, N1, N2)

foo([1, 2])
