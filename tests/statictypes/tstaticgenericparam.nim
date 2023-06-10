# static types that depend on a generic parameter

block: # issue #19365
  var ss: seq[string]
  proc f[T](x: static T) =
    ss.add($x & ": " & $T)

  f(123)
  doAssert ss == @["123: int"]
  f("abc")
  doAssert ss == @["123: int", "abc: string"]

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
  # `untyped` needed here for now because compiler expects `T` to support `+`:
  type Foo[T; U: static T] = array[T(0) .. untyped U + 1, int]

  block:
    var x: Foo[int, 1]
    x[0] = 1
    x[1] = 2
    x[2] = 3
    doAssert x == [0: 1, 1: 2, 2: 3]
    doAssert x is array[0 .. 2, int]
