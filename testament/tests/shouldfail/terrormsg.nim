discard """
  errormsg: "wrong error message"
  targets: "c"
  line: 9
  column: 6
"""

# test should fail because the line directive is wrong
echo undeclared
