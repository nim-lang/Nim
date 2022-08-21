discard """
  exitcode: 1
  outputsub: "[FAILED] with exception"
"""

# see also: `tests/stdlib/tunittest_error.nim`

import unittest

proc ddd() =
  raise newException(IOError, "didn't do stuff")

proc ccc() =
  ddd()

proc bbb() =
  ccc()

proc aaa() =
  bbb()

test "with exception":
  check 3 == 3
  aaa()
