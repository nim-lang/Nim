proc bar(x: int): int = 10
template foo =
  proc bar(x: int): int {.inject.} = x + 2
  doAssert bar(3) == 5
  doAssert 3.bar == 5
block:
  foo()
