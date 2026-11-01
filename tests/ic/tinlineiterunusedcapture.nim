discard """
  description: "IC preserves demand-time capture validation for unused inline iterators"
"""

#? metamorphic

#!FILE helper.nim
# This iterator is exported but never expanded by this program. Capture
# validation in the classic compiler happens when an iterator is expanded.
iterator unused*(value: var int): int =
  let read = proc(): int = value
  yield read()

proc used*(): int = 42

#!FILE main.nim
import helper
echo used()
#!STEP expect: 42
