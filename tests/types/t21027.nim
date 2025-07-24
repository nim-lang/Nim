discard """
  errormsg: "Invalid usage of cast, cast requires a type to convert to, e.g., cast[int](0d)."
"""
# bug #21027
let x: uint64 = cast(5)
