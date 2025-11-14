# Test case: Ambiguous identifier from multiple imports
# WHY IT MATTERS: When multiple modules export the same symbol,
# developers get confused about which one is being used or
# why there's a conflict.

# Simulate importing two modules that both export 'getValue'
# (In real code, this would be actual imports)

# Let's create a realistic example with os and strutils
import std/[os, strutils]

# Both modules might have similar functions
# Let's use a case where we get ambiguity

proc demonstrateAmbiguity() =
  # If we had two modules both exporting 'split'
  # The error message will now show:
  # - WHERE each 'split' comes from
  # - Which module exported it
  # - HOW to disambiguate (module.symbol syntax)

  # Example of ambiguous import (if such existed):
  # let parts = split("hello,world", ",")
  #
  # EXPECTED IMPROVED ERROR:
  # Error:[EXXXX]: ambiguous identifier: 'split'
  #
  # note: 'split' is available from multiple sources:
  #   candidate 1 from module 'strutils' (type: proc(s: string, sep: char): seq[string])
  #    --> strutils.nim(245, 6)
  #   candidate 2 from module 'sequtils' (type: proc[T](s: seq[T], pred: proc): tuple)
  #    --> sequtils.nim(156, 6)
  #
  # help: use qualified access to disambiguate:
  #   - strutils.split
  #   - sequtils.split

  # For demonstration, let's use a symbol that actually might be ambiguous
  echo "This demonstrates how improved errors help with import confusion"

demonstrateAmbiguity()
