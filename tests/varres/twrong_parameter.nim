discard """
  line: 6
  errormsg: "'x' is not the first parameter; context: 'x'"
"""

proc forward(abc: int; x: var int): var int = result = x

proc foo(): var int =
  var y = 9
  result = forward(45, y)

echo foo()
