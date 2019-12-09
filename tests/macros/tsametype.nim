discard """
output: '''true
false
true
false
true
false
true
false
true
false'''
joinable: false
"""

import macros

macro same(a: typedesc, b: typedesc): untyped =
  newLit(a.getType[1].sameType b.getType[1])

echo same(int, int)
echo same(int, float)

type
  SomeInt = int
  DistinctInt = distinct int
  SomeFloat = float
  DistinctFloat = distinct float

echo same(int, SomeInt)
echo same(int, DistinctInt)
echo same(float, SomeFloat)
echo same(float, DistinctFloat)

type
  Obj = object of RootObj
  SubObj = object of Obj
  Other = object of RootObj

echo same(Obj, Obj)
echo same(int, Obj)
echo same(SubObj, SubObj)
echo same(Other, Obj)
