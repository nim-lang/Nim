

proc byReturn(n: int): auto =
  if n < 5:
    return byReturn(n + 1)
  else:
    return 9

proc byResult(n: int): auto =
  if n < 5:
    result = byResult(n + 1)
  else:
    result = 9

proc byExpression(n: int): auto =
  if n < 5:
    byExpression(n + 1)
  else:
    9

proc generic[T](x: T; n: int): auto =
  if n < 5:
    return generic(x, n + 1)
  else:
    return x

proc concreteFirst(n: int): auto =
  if n >= 5:
    return 9
  else:
    return concreteFirst(n + 1)

proc multipleRecursiveBranches(n: int): auto =
  if n < 0:
    return multipleRecursiveBranches(n + 1)
  elif n < 5:
    return multipleRecursiveBranches(n + 1)
  else:
    return 9

doAssert byReturn(3) == 9
doAssert byResult(3) == 9
doAssert byExpression(3) == 9
doAssert generic("ok", 3) == "ok"
doAssert concreteFirst(3) == 9
doAssert multipleRecursiveBranches(-1) == 9
