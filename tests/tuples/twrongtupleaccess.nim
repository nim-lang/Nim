discard """
  errormsg: "attempting to call undeclared routine: \'setBLAH\'"
  file: "twrongtupleaccess.nim"
  line: 9
"""
# Bugfix

var v = (5.0, 10.0)
v.setBLAH(10)
