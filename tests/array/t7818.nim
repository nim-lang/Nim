discard """
  msg: '''BracketExpr
  Sym "array"
  Infix
    Ident ".."
    IntLit 0
    IntLit 2
  BracketExpr
    Sym "Vehicle"
    Sym "int"
---------
BracketExpr
  Sym "array"
  Infix
    Ident ".."
    IntLit 0
    IntLit 2
  BracketExpr
    Sym "Vehicle"
    Sym "int"
---------'''
"""

# bug #7818
# this is not a macro bug, but array construction bug
# I use macro to avoid object slicing
# see #7712 and #7637
import macros

type
  Vehicle[T] = object of RootObj
    tire: T
  Car[T] = object of Vehicle[T]
  Bike[T] = object of Vehicle[T]

macro peek(n: typed): untyped =
  echo getTypeImpl(n).treeRepr
  echo "---------"

var v = Vehicle[int](tire: 3)
var c = Car[int](tire: 4)
var b = Bike[int](tire: 2)

peek([c, b, v])
peek([v, c, b])
