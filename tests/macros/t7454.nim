discard """
errormsg: "expression has no type:"
line: 8
"""

macro p(t: typedesc): typedesc =
  discard
var a: p(int)
