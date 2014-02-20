discard """
  output: "Sortable\nSortable\nContainer"
"""

import typetraits

type
  TObj = object
    x: int

  Sortable = generic x, y
    (x < y) is bool

  ObjectContainer = generic C
    C.len is ordinal
    for v in items(C):
      v.type is tuple|object

proc foo(c: ObjectContainer) =
  echo "Container"

proc foo(x: Sortable) =
  echo "Sortable"

foo 10
foo "test"
foo(@[TObj(x: 10), TObj(x: 20)])

proc intval(x: int) = discard

# check real and virtual fields
type
  TFoo = generic T
    T.x
    y(T)
    intval T.y
    
proc y(x: TObj): int = 10

proc testFoo(x: TFoo) = discard
testFoo(TObj(x: 10))

