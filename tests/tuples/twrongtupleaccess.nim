discard """
  file: "twrongtupleaccess.nim"
  line: 9
  errormsg: "attempting to call undeclared procedure field: \'setBLAH\'"
"""
# Bugfix

var v = (5.0, 10.0)
v.setBLAH(10)

