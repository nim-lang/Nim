iterator xy[T](a: T, b: set[T]): T =
  if a in b:
    yield a

for a in xy(1'i8, {}):
  for b in xy(a, {}):
    echo a
