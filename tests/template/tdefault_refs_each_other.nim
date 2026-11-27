discard """
  errormsg: "the default value of 'a' refers back to 'a'"
  line: 6
"""

template t(a: untyped = b, b: untyped = a) =
  discard a

t()
