proc moo1(this: int) =
  doAssert this == 42

proc moo2(x: int) =
  var this = x
  doAssert this == 42

proc moo3() =
  for this in [1,1,1]:
    doAssert this == 1

proc moo4() =
  type
    X = object
      this: int

  var q = X(this: 42)
  doAssert q.this == 42

moo1(42)
moo2(42)
moo3()
moo4()
