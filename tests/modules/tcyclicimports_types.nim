discard """
  output: "1"
  cmd: "nim c -r $file"
"""

import mcyclicimports_types

type
  T* = object
    value*: int

proc makeT(): T =
  T(value: 1)

echo id(makeT()).value
