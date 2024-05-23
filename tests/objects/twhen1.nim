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
discard MyObject(x: 100, y: 200)

block: # Ensure when evaluates properly in objects
  type X[bits: static int] = object #22474
    when bits >= 256:
     data32: byte
    else:
     data16: byte

  static:
    discard X[255]().data16
    discard X[256]().data32


  type ComplexExprObject[S: static string, I: static int, Y: static auto] = object
    when 'h' in S and I < 10 and Y isnot float:
      a: int
    elif I > 30:
      b: int
    elif typeof(Y) is float:
      c: int
    else:
      d: int

  static:
    discard ComplexExprObject["hello", 9, 300i32]().a
    discard ComplexExprObject["", 40, 30f]().b
    discard ComplexExprObject["", 20, float 30]().c
    discard ComplexExprObject["", 20, ""]().d



