discard """
  errormsg: "Closure iterators are not supported by VM!"
"""

iterator iter*(): int {.closure.} =
  yield 3

static:
  var x = iter
