import typetraits

type
  AnyMatrix*[R, C: static[int]; T] = concept m, var mvar, type M
    M.ValueType is T
    M.Rows == R
    M.Cols == C

    m[int, int] is T
    mvar[int, int] = T

    type TransposedType = stripGenericParams(M)[C, R, T]

  AnySquareMatrix*[N: static[int], T] = AnyMatrix[N, N, T]

  AnyTransform3D* = AnyMatrix[4, 4, float]

proc transposed*(m: AnyMatrix): m.TransposedType =
  for r in 0 ..< m.R:
    for c in 0 ..< m.C:
      result[r, c] = m[c, r]

proc determinant*(m: AnySquareMatrix): int =
  return 0

proc setPerspectiveProjection*(m: AnyTransform3D) =
  discard

