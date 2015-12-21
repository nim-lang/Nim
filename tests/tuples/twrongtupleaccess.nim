discard """
  line: 8
  errormsg: "attempting to call undeclared routine: \'setBLAH\'"
"""
# Bugfix

var v = (5.0, 10.0)
v.setBLAH(10)
