discard """
  output: '''Inh
45'''
"""

type
  Base = ref object of RootObj
    field: int

  Inh = ref object of Base

# bug #6777
method foo(b: Base): var int {.base.} =
  echo "Base"
  result = b.field

method foo(b: Inh): var int =
  echo "Inh"
  result = b.field

var x: Base
var y = Inh(field: 45)
x = y
echo foo(x)

