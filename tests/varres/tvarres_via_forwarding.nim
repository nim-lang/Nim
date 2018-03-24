discard """
  line: 10
  errormsg: "'y' escapes its stack frame; context: 'forward(y)'"
"""

proc forward(x: var int): var int = result = x

proc foo(): var int =
  var y = 9
  result = forward(y)

echo foo()
