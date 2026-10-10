template a(T: type): int =
  when T is uint64: 1 else: 2

type
  M*[T] = object
    data*: seq[T]
    b: seq[int]
    indices*: array[a(T), int64]
  U = distinct uint64
  D* = object
    c: M[U]
    v: array[180000, int64]
    g*: M[uint64]