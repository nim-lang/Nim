discard """
  file: "tenumitems.nim"
  line: 8
  errormsg: "attempting to call undeclared routine: 'items'"
"""

type a = enum b,c,d
a.items()
