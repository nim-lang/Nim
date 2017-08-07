import math

type
  TMatrix*[T; R, C: static[int]] = array[R, array[C, T]] ## Row major matrix type.
  TMat4* = TMatrix[float32, 4, 4]
  TVector*[T; C: static[int]] = array[C, T]
  TVec4* = TVector[float32, 4]

template row*[T; R, C: static[int]](m: TMatrix[T, R, C], rowidx: range[0..R-1]): TVector[T, R] =
  m[rowidx]

proc col*[T; R, C: static[int]](m: TMatrix[T, R, C], colidx: range[0..C-1]): TVector[T, C] {.noSideEffect.} =
  for i in low(m)..high(m):
    result[i] = m[i][colidx]

proc dot(lhs, rhs: TVector): float32 =
  for i in low(rhs)..high(rhs):
    result += lhs[i] * rhs[i]

proc `*`*[T; R, N, C: static[int]](a: TMatrix[T, R, N], b: TMatrix[T, N, C]): TMatrix[T, R, C] {.noSideEffect.} =
  for i in low(a)..high(a):
    for j in low(a[i])..high(a[i]):
      result[i][j] = dot(a.row(i), b.col(j))

proc translate*(v: TVec4): TMat4 {.noSideEffect.} =
  result = [[1f32, 0f32, 0f32, 0f32],
            [0f32, 1f32, 0f32, 0f32],
            [0f32, 0f32, 1f32, 0f32],
            [v[0], v[1], v[2], 1f32]]

proc rotatex*(angle: float): TMat4 =
  result = [[1f32,          0f32,           0f32,           0f32],
            [0f32, cos(angle).float32, sin(angle).float32,  0f32],
            [0f32, -sin(angle).float32, cos(angle).float32, 0f32],
            [0f32,          0f32,           0f32,           1f32]]

proc orbitxAround(point: TVec4, angle: float): TMat4 =
  result = translate(point)*rotatex(angle)*translate(point)

