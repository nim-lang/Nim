type
  VarContainer[T] = concept c
    put(var c, T)

  AltVarContainer[T] = concept var c
    put(c, T)

  NonVarContainer[T] = concept c
    put(c, T)

  GoodContainer = object
    x: int

  BadContainer = object
    x: int

proc put(x: BadContainer, y: int) = discard
proc put(x: var GoodContainer, y: int) = discard

template ok(x) = assert(x)
template no(x) = assert(not(x))

static:
  ok GoodContainer is VarContainer[int]
  ok GoodContainer is AltVarContainer[int]
  no BadContainer is VarContainer[int]
  no BadContainer is AltVarContainer[int]
  ok GoodContainer is NonVarContainer[int]
  ok BadContainer is NonVarContainer[int]

