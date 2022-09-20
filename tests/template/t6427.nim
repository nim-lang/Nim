discard """
  action: compile
"""
import typetraits

template bar(name: untyped; b1, b2: int8) =
  let name: array[2, int8] = [b1, b2]

bar(y, 0x11, 0x22)