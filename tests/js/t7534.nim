proc f(x: int): int =
  result = case x
    of 1: 2
    elif x == 2: 3
    else: 1

doAssert 2 == f(f(f(f(1))))
