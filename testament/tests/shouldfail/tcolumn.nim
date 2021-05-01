discard """
  errormsg: "undeclared identifier: 'undeclared'"
  targets: "c"
  line: 9
  column: 7
"""

# test should fail because the line directive is wrong
echo undeclared
