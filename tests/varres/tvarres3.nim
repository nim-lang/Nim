discard """
  output: "45"
"""

var
  g = 5

proc p(): var int =
  var bla = addr(g) #: array[0..7, int]
  result = bla[]

p() = 45

echo g

