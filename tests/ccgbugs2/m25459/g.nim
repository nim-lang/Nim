proc v[T](_: typedesc[T]): int =
  if T is int64: 6 else: 4

type
  D*[T] = object
    c*: seq[T]
    k*: array[v(T), int]
  F = distinct int64
  W* = object
    y: D[F]
    j*: D[int64]
