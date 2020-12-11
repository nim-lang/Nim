const Z = 0

type
  Foo[T] = object
   when true:
     u: int
   else:
     v: int
  Foo1[T] = object
   when T is int:
     x: T
   elif true:
     z: char
  Foo2[x:static[int]] = object
    when (x and 1) == 1:
      x: array[x+1,int]
    else:
      x: array[x,int]

  Foo3 = Foo2[128]

  # #8417
  Foo4[A: static[int]] = object
    when Z == 0:
      discard
    else:
      discard

block:
  var x: Foo[int] = Foo[int](u: 42)
  doAssert x.u == 42

# Don't evaluate `when` branches before the type is instantiated
block:
  var x: Foo1[bool] = Foo1[bool](z: 'o')
  doAssert x.z == 'o'

block:
  var x: Foo2[3]
  doAssert x.x.len == 4

block:
  var x: Foo2[4]
  doAssert x.x.len == 4

block:
  var x: Foo3
  doAssert x.x.len == 128

block:
  var x: Foo4[0]

type
  MyObject = object
    x: int
    when (NimMajor, NimMinor) >= (1, 1):
      y: int
