discard """
  line: 10
  errormsg: "expression has no address"
"""

var
  g = 5

proc p(): var int =
  result = 89

p() = 45

echo g
