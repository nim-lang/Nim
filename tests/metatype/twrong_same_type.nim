# bug #23445

template mapIt*(x: untyped): untyped =
  type OutType {.gensym.} = typeof(x) #typeof(x, typeOfProc)
  newSeq[OutType](5)

type F[E] = object

proc start(v: int): F[(ValueError,)] = discard
proc stop(v: int): F[tuple[]] = discard

assert $typeof(mapIt(start(9))) == "seq[F[(ValueError,)]]"
assert $typeof(mapIt(stop(9))) == "seq[F[tuple[]]]"
