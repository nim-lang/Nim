discard """
  line: 7
  errormsg: "expression 'items' cannot be called"
"""

type a = enum b,c,d
a.items()


