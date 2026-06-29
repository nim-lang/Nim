discard """
  targets: "c cpp"
  matrix: "-d:checkAbi"
"""

proc v[T](_: typedesc[T]): int =
  if T is int64: 2 else: 1

type
  D[T] = object
    k: array[v(T), int]
  E[T] = object
    k: array[v(T), int]
  F = distinct int64
  W = object
    a: D[int64]
    b: D[F]

proc csizeof[T](x {.bycopy.} : T): cint {.importc: "sizeof", nodecl.}

var w: W
assert sizeof(w) == csizeof(w)

var
  e0: E[F]
  e1: E[int64]
assert sizeof(e0) == csizeof(e0)
assert sizeof(e1) == csizeof(e1)

var tup: (E[F], E[int64])
assert sizeof(tup) == csizeof(tup)
