discard """
  errormsg: "'bla' escapes its stack frame; context: 'bla'"
  file: "tvarres1.nim"
  line: 12
"""

var
  g = 5

proc p(): var int =
  var bla: int
  result = bla

p() = 45

echo g
