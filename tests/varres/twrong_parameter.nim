discard """
  line: 10
  errormsg: "'x' is not the first parameter; context: 'x.field[0]'"
"""

type
  MyObject = object
    field: array[2, int]

proc forward(abc: int; x: var MyObject): var int = result = x.field[0]

proc foo(): var int =
  var y: MyObject
  result = forward(45, y)

echo foo()
