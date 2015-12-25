discard """
  output: '''true
false
true
false
true
false
true
false'''
"""

import macros

macro test(a: typed, b: typed): expr =
  newLit(a == b)

echo test(1, 1)
echo test(1, 2)

type
  Obj = object of RootObj
  Other = object of RootObj

echo test(Obj, Obj)
echo test(Obj, Other)

var a, b: int

echo test(a, a)
echo test(a, b)

macro test2: expr =
  newLit(bindSym"Obj" == bindSym"Obj")

macro test3: expr =
  newLit(bindSym"Obj" == bindSym"Other")

echo test2()
echo test3()
