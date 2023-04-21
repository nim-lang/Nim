proc fooFunc(c: int): bool =
  result = c in {'a'.ord .. 'z'.ord}

static:
  var c = 194708
  echo fooFunc(c)
