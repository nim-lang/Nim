
import subdir / subdir_b / utils

## This is the top level module.
runnableExamples:
  doAssert bar(3, 4) == 7
  foo(1, 2)


template foo*(a, b: SomeType) =
  ## This does nothing
  ##
  discard

proc bar*[T](a, b: T): T =
  result = a + b

import std/macros

macro bar*(): untyped =
  result = newStmtList()
