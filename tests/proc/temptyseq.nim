discard """
  errormsg: "cannot infer the type of parameter 'y'"
  line: 6
"""

proc bar(y = @[]) = discard
