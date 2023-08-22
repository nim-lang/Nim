discard """
  errormsg: "cannot infer the return type of 'bar'"
  line: 6
"""

iterator bar(): auto =
  discard
for t in bar():
  discard
