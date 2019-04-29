discard """
  errormsg: "cannot infer the type of parameter 'x'"
  line: 6
"""

proc foo(x = []) = discard
