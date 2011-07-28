discard """
  file: "tvarres2.nim"
  line: 11
  errormsg: "expression has no address"
"""

var
  g = 5

proc p(): var int = 
  result = 89
  
p() = 45

echo g

