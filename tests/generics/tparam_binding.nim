discard """
  errormsg: "got <ref Matrix[2, 2, system.float], ref Matrix[2, 1, system.float]>"
  line: 27
"""

type
  Matrix[M,N: static[int]; T: SomeFloat] = distinct array[0..(M*N - 1), T]

let a = new Matrix[2,2,float]
let b = new Matrix[2,1,float]

proc foo[M,N: static[int],T](a: ref Matrix[M, N, T], b: ref Matrix[M, N, T])=
  discard

foo(a, a)

proc bar[M,N: static[int],T](a: ref Matrix[M, M, T], b: ref Matrix[M, N, T])=
  discard

bar(a, b)
bar(a, a)

proc baz[M,N: static[int],T](a: ref Matrix[N, N, T], b: ref Matrix[M, N, T])=
  discard

baz(a, a)
baz(a, b)

