discard """
  targets: "c cpp"
"""

import std/atomics
type Futex = distinct Atomic[int32]

var x: Futex
