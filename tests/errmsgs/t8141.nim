discard """
  errormsg: "set is too large; use `std/sets` for ordinal types with more than 2^16 elements"
  line: 9
  column: 6
"""

# bug #8141: used to crash the compiler
type OhNo[ES] = set[ES]
type What = OhNo[int]

var x: What
