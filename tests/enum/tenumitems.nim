discard """
  line: 7
  errormsg: "attempting to call undeclared procedure: 'items'"
"""

type a = enum b,c,d
a.items()


