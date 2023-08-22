discard """
  errormsg: "expression has no address"
  file: "tvarres2.nim"
  line: 11
"""

var
  g = 5

proc p(): var int =
  result = 89

p() = 45

echo g
