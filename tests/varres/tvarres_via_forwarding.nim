discard """
  errormsg: "'y' escapes its stack frame; context: 'forward(y)'"
  line: 10
"""

proc forward(x: var int): var int = result = x

proc foo(): var int =
  var y = 9
  result = forward(y)

echo foo()
