discard """
errormsg: "Only one finally is allowed after all other branches"
"""

try:
  discard
finally:
  discard
finally:
  discard


