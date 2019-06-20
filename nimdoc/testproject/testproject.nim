
import subdir / subdir_b / utils

## This is the top level module.
runnableExamples:
  import subdir / subdir_b / utils
  doAssert bar(3, 4) == 7
  foo(enumValueA, enumValueB)
  # bug #11078
  for x in "xx": discard


template foo*(a, b: SomeType) =
  ## This does nothing
  ##
  discard

proc bar*[T](a, b: T): T =
  result = a + b

proc baz*[T](a, b: T): T {.deprecated.} =
  ## This is deprecated without message.
  result = a + b

proc buzz*[T](a, b: T): T {.deprecated: "since v0.20".} =
  ## This is deprecated with a message.
  result = a + b

import std/macros

macro bar*(): untyped =
  result = newStmtList()

var aVariable*: array[1,int]

aEnum()
bEnum()

# bug #9432
proc isValid*[T](x: T): bool = x.len > 0
