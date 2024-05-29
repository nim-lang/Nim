discard """
  errormsg: "Closure iterators are not supported by JS backend!"
"""

iterator iter*(): int {.closure.} =
  yield 3

var x = iter
doAssert x() == 3

let fIt = iterator(): int = yield 70
doAssert fIt() == 70
