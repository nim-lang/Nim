import macros

macro symFromDesc(T: typedesc): untyped =
  let typ = getType(T)
  typ[1]

template produceType(T: typedesc): untyped =
  type
    XT = object
      x: symFromDesc(T)

  XT

type
  X[T] = produceType(T)

var x: X[int]
