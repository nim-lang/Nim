discard """
  output: '''Sortable
Sortable
Container
true
true
false
false
false
'''
"""

import typetraits

type
  TObj = object
    x: int

  Sortable = concept x, y
    (x < y) is bool

  ObjectContainer = concept C
    C.len is Ordinal
    for v in items(C):
      v.type is tuple|object

proc foo(c: ObjectContainer) =
  echo "Container"

proc foo(x: Sortable) =
  echo "Sortable"

foo 10
foo "test"
foo(@[TObj(x: 10), TObj(x: 20)])

proc intval(x: int): int = 10

# check real and virtual fields
type
  TFoo = concept T
    T.x
    y(T)
    intval T.y
    let z = intval(T.y)

proc y(x: TObj): int = 10

proc testFoo(x: TFoo) = discard
testFoo(TObj(x: 10))

type
  Matrix[Rows, Cols: static[int]; T] = concept M
    M.M == Rows
    M.N == Cols
    M.T is T

  MyMatrix[M, N: static[int]; T] = object
    data: array[M*N, T]

var x: MyMatrix[3, 3, int]

echo x is Matrix
echo x is Matrix[3, 3, int]
echo x is Matrix[3, 3, float]
echo x is Matrix[4, 3, int]
echo x is Matrix[3, 4, int]

