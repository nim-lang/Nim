discard """
  nimout: "a is deprecated"
"""

var
  a {.deprecated.}: array[0..11, int]

a[8] = 1

