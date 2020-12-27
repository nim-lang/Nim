discard """
  targets: "c cpp js"
  action: compile
"""

import std/unrolling

for i in unroll(0, 100, 5):
  echo i
