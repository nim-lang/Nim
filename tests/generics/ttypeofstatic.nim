block: # issue #24715
  type H[c: static[float64]] = object
    value: typeof(c)

  proc u[T: H](_: typedesc[T]) =
    discard default(T)

  u(H[1'f64])

block: # issue #24743
  type
    K[w: static[auto]] = typeof(w)
    V = object
      a: K[0]
    GenericV[w: static[auto]] = object
      a: typeof(w)

  var x: GenericV[0]
  doAssert x.a is int
  var y: GenericV["abc"]
  doAssert y.a is string
