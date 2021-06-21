discard """
  errormsg: "Closure iterators are not supported by JS backend!"
"""

iterator iter*(): int {.closure.} =
  yield 3

var x = iter
