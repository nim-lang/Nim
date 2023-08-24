
template elementType(a: untyped): typedesc =
  typeof(block: (for ai in a: ai))

func fn[T](a: T) =
  doAssert elementType(a) is int

@[1,2,3].fn