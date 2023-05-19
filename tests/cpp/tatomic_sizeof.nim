discard """
  targets: "cpp"
"""

import std/atomics

doAssert sizeOf(Atomic[int]) == sizeOf(int)
doAssert sizeOf(Atomic[bool]) == sizeOf(bool)
