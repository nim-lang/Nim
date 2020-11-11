discard """
  errormsg: "cannot infer the type of parameter 'x'"
  line: 5
"""
proc a(x = {}) = discard
