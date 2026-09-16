type Selector*[A, R] = object
  value*: int

template restoreState*(self: untyped = (), state: untyped = ()): untyped =
  Selector[int, string](value: 42)

proc restoreState*(self: int, state: string) =
  discard
