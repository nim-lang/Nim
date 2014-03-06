discard """
  output: '''true
true
false
yes'''
"""

proc IsVoid[T](): string = 
  when T is void:
    result = "yes"
  else:
    result = "no"

const x = int is int
echo x, " ", float is float, " ", float is string, " ", IsVoid[void]()

template yes(e: expr): stmt =
  static: assert e

template no(e: expr): stmt =
  static: assert(not e)

var s = @[1, 2, 3]

yes s.items is iterator
no  s.items is proc

yes s.items is iterator: int
no  s.items is iterator: float

yes s.items is iterator: TNumber
no  s.items is iterator: object

type 
  Iter[T] = iterator: T

yes s.items is Iter[TNumber]
no  s.items is Iter[float]

