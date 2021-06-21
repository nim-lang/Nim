iterator cycle*[T](s: openArray[T]): T =
  let s = @s
  for x in s:
    yield x
