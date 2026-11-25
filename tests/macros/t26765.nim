discard """
  output: "passed"
"""

import std/macros

template t(x: typed): untyped = x
macro m(): untyped =
  t(quote do: echo "passed")
m()
