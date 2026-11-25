discard """
  matrix: "--mm:orc; --mm:arc; --mm:refc"
  output: "A[int]: 101  B[3]: 101"
"""

# bug #26680: every instantiation of `B[n]` with `n = 3` created a new
# `B[3]`; the instance in `test` had no `=sink` and the old value of `b`
# was destroyed before `g(b)` read it.
type
  A[T] = ref object
    v: int
  B[n: static int] = ref object
    v: int

proc newA[T](v: int): A[T] = A[T](v: v)
proc g[T](x: A[T]): A[T] =
  let t = A[T](v: 100)
  A[T](v: x.v + t.v)
proc f[T](x: A[T]): A[T] = A[T](v: x.v)

proc newB[n: static int](v: int): B[n] = B[n](v: v)
proc g[n: static int](x: B[n]): B[n] =
  let t = B[n](v: 100)
  B[n](v: x.v + t.v)
proc f[n: static int](x: B[n]): B[n] = B[n](v: x.v)

proc test() =
  var a = newA[int](1)
  a = f(g(a))
  var b = newB[3](1)
  b = f(g(b))
  echo "A[int]: ", a.v, "  B[3]: ", b.v
test()
