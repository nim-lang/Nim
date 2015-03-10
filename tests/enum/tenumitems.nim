discard """
  line: 7
  errormsg: "undeclared identifier: 'items'"
"""

type a = enum b,c,d
a.items()


