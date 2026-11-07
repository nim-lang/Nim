iterator items(a: int): int = yield a

template t(a: int): untyped =
  for x in a:
    result += x

proc p*(a: int | uint): int =
  for x in a:
    result += x

proc q*(a: int | uint): int =
  t a

type Bag* = object
  data*: seq[int]

iterator items*(b: Bag): int =
  for x in b.data: yield x

proc sum*[T](b: T): int =
  for x in b: result += x
  for x in @[1, 2]: result += x
