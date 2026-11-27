# bug #10739: a generic param's constraint can refer to an earlier one
type
  Obj[A; B: not A] = object
  Obj3[A: SomeInteger; B: A] = object
  O2 = Obj[int, float]
  O4 = Obj3[int, int]

var x: O2
var y: O4
doAssert not compiles(Obj[int, int])
doAssert not compiles(Obj3[int, float])
doAssert compiles(Obj[int, string])
doAssert compiles(Obj3[int8, int8])
