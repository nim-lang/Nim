import math

block: # issue #19916
  type
    Test[S: static[Natural]] = object
      a: array[ceilDiv(S, 8), uint8]

  let a = Test[32]()
  doAssert a.a.len == 4

block: # issue #20514
  type Foo[S:static[array[2, int]]] = object
    values: array[prod(S), float]

  doAssert Foo[[4,5]]().values.len == 20

block: # issue #20937
  type
    Vec3[T: SomeNumber] {.bycopy.} = tuple[x, y, z: T]

  func volume[T](v: Vec3[T]): T =
    when T is SomeUnsignedInt:
      v.x * v.y * v.z
    else:
      abs (v.x * v.y * v.z)

  type
    Matrix3[C: static Vec3[uint], T] = object
      cells: array[C.volume, T]

  let m = Matrix3[(1.uint, 1.uint, 1.uint), uint](cells: [0.uint])
  let m2 = Matrix3[(4.uint, 3.uint, 5.uint), uint]()
  doAssert m2.cells.len == 60

block:  # issue #19284
  type Board[N, M: static Slice[int]] = array[len(N)*len(M), int8]

  var t: Board[0..4, 0..4]
  doAssert t.len == 25

block: # minimal issue #19284
  proc foo[T](x: T): int =
    result = 0
  type Foo[N: static int] = array[0..foo(N), int]

  var t: Foo[5]
  doAssert t.len == 1
