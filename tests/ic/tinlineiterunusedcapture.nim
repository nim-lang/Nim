discard """
  description: "IC lowers inline iterators at their declaration: an illegal capture is an error even when unused"
"""

#? metamorphic

# Under `--ic:on` an inline iterator is lambda-lifted by the `lower` stage of
# the module that declares it, whether or not anything expands it. An illegal
# capture is thus reported at the declaration, not at the first expansion.
# `nim c` keeps diagnosing it lazily, hence `no-oracle` on the failing steps.

#!FILE helper.nim
proc used*(): int = 42

#!FILE main.nim
import helper
echo used()
#!STEP expect: 42
#!STEP expect: 42
#!STEP expect: 42; noop

# A `var` parameter captured by a nested closure.
#!FILE helper.nim
iterator unused*(value: var int): int =
  let read = proc(): int = value
  yield read()

proc used*(): int = 42
#!STEP fails: cannot be captured; no-oracle
#!STEP fails: cannot be captured; no-oracle

# A named nested routine capturing an `openArray` parameter (a view as well).
#!FILE helper.nim
iterator unusedNamed*(values: openArray[int]): int =
  proc read(): int = values[0]
  yield read()

proc used*(): int = 42
#!STEP fails: cannot be captured; no-oracle

# Private and unused: the declaration alone is enough.
#!FILE helper.nim
iterator hidden(value: var int): int =
  let read = proc(): int = value
  yield read()

proc used*(): int = 42
#!STEP fails: cannot be captured; no-oracle

# Removing the declaration makes the program valid again.
#!FILE helper.nim
proc used*(): int = 42
#!STEP expect: 42
#!STEP expect: 42
#!STEP expect: 42; noop
