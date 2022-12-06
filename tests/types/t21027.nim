discard """
  errormsg: "expression 'cast(5)' has no type (or is ambiguous)"
"""
# bug #21027
let x: uint64 = cast(5)
