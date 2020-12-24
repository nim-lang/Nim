discard """
  errormsg: "undeclared identifier: 'z'"
  line: 11
"""

# Open a new scope for static expr blocks
block:
  let a = static:
    var z = 123
    33
  echo z
