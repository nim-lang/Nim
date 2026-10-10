discard """
  joinable: false
  output: "42"
"""

# the pragma of `dir/m {.cyclic.}` belongs to the last part of the path:
import sub/mcyclic_path {.cyclic.}

type
  Outer* = object
    inner*: Inner

proc fa*(): int = fb() + 1

echo fa()
