discard """
  line: 7
  errormsg: "attempting to call undeclared routine: 'items'"
"""

type a = enum b,c,d
a.items()


