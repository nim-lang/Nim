discard """
  errormsg: "set is too large; use `std/sets` for ordinal types with more than 2^16 elements"
"""

type
  Foo = set[Bar]
  Bar = int32
