discard """
  description: "IC preserves demand-time capture validation for unused inline iterators"
"""

#? metamorphic

#!FILE helper.nim
# These iterators are exported but never expanded by the initial program. Capture
# validation in the classic compiler happens when an iterator is expanded.
iterator unused*(value: var int): int =
  let read = proc(): int = value
  yield read()

# Named nested routines are reached through symbol references, and openArray
# parameters are views too.
iterator unusedNamed*(values: openArray[int]): int =
  proc read(): int = values[0]
  yield read()

# Eagerly transforming a wrapper would also expand the unsafe iterator.
iterator unusedWrapper*(value: var int): int =
  for x in unused(value):
    yield x

proc used*(): int = 42

#!FILE main.nim
import helper
echo used()
#!STEP expect: 42
#!STEP expect: 42
#!STEP expect: 42; noop

# Once expanded, both backends must still reject the unsafe capture, including
# on a repeated build after the first failure.
#!FILE main.nim
import helper
var value = 1
for x in unused(value):
  echo x
#!STEP fails: cannot be captured
#!STEP fails: cannot be captured

#!FILE main.nim
import helper
var value = 1
for x in unusedWrapper(value):
  echo x
#!STEP fails: cannot be captured

#!FILE main.nim
import helper
for x in unusedNamed([1]):
  echo x
#!STEP fails: cannot be captured

# Removing the use makes the same declaration harmless again.
#!FILE main.nim
import helper
echo used()
#!STEP expect: 42
#!STEP expect: 42; noop
