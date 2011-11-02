discard """
  line: 7
  errormsg: "a type has no value"
"""

type a = enum b,c,d
a.items()


