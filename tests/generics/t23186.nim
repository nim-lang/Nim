# issue #23186

template typedTempl(x: int, body): untyped =
  body

proc generic1[T]() =
  discard

proc generic2[T]() =
  typedTempl(1):
    let x = generic1[T]

generic2[int]()
