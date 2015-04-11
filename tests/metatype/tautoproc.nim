discard """
  output: "empty"
"""

# bug #898

import typetraits

proc measureTime(e: auto) =
  echo e.type.name

proc generate(a: int): void =
  discard

proc runExample =
  var builder: int = 0

  measureTime:
    builder.generate()

measureTime:
  discard
