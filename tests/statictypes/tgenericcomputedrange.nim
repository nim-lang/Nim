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
  doAssert m.cells.len == 1
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

block:
  type Foo[T; U: static T] = range[T(0) .. U]

  block:
    var x: array[Foo[int, 1], int]
    x[0] = 1
    x[1] = 2
    doAssert x == [0: 1, 1: 2]
    doAssert x is array[0 .. 1, int]

  block:
    type Bar = enum a, b, c
    var x: array[Foo[Bar, c], int]
    x[a] = 1
    x[b] = 2
    x[c] = 3
    doAssert x == [a: 1, b: 2, c: 3]
    doAssert x is array[a .. c, int]

block:
  type Foo[T; U: static T] = array[T(0) .. U, int]

  block:
    var x: Foo[int, 1]
    x[0] = 1
    x[1] = 2
    doAssert x == [0: 1, 1: 2]
    doAssert x is array[0 .. 1, int]

  block:
    type Bar = enum a, b, c
    var x: Foo[Bar, c]
    x[a] = 1
    x[b] = 2
    x[c] = 3
    doAssert x == [a: 1, b: 2, c: 3]
    doAssert x is array[a .. c, int]

block:
  type Foo[T; U: static T] = array[T(0) .. U + 1, int]

  block:
    var x: Foo[int, 1]
    x[0] = 1
    x[1] = 2
    x[2] = 3
    doAssert x == [0: 1, 1: 2, 2: 3]
    doAssert x is array[0 .. 2, int]

block:
  type Foo[T; U: static T] = array[T(0) .. (U * 2) + 1, int]

  block:
    var x: Foo[int, 1]
    x[0] = 1
    x[1] = 2
    x[2] = 3
    x[3] = 4
    doAssert x == [0: 1, 1: 2, 2: 3, 3: 4]
    doAssert x is array[0 .. 3, int]

block: # issue #22187
  template m(T: type, s: int64): int64 = s
  func p(n: int64): int = int(n)
  type F[T; s: static int64] = object
    k: array[p(m(T, s)), int64]
  var x: F[int, 3]
  doAssert x.k is array[3, int64]

block: # issue #22490
  proc log2trunc(x: uint64): int =
    if x == 0: int(0) else: int(0)
  template maxChunkIdx(T: typedesc): int64 = 0'i64
  template layer(vIdx: int64): int = log2trunc(0'u64)
  type HashList[T] = object
    indices: array[int(layer(maxChunkIdx(T))), int]
