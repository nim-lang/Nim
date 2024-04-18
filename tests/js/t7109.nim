iterator iter*(): int {.closure.} =
  yield 3

var x = iter
doAssert x() == 3
