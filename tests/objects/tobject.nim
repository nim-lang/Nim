import unittest

type Obj = object
  foo: int

proc makeObj(x: int): Obj =
  result.foo = x

block: # object basic methods
  block: # it should convert an object to a string
    var obj = makeObj(1)
    # Should be "obj: (foo: 1)" or similar.
    check($obj == "(foo: 1)")
  block: # it should test equality based on fields
    check(makeObj(1) == makeObj(1))

# bug #10203

type
  TMyObj = TYourObj
  TYourObj = object of RootObj
    x, y: int

proc init: TYourObj =
  result.x = 0
  result.y = -1

proc f(x: var TYourObj) =
  discard

var m: TMyObj = init()
f(m)

var a: TYourObj = m
var b: TMyObj = a

# bug #10195
type
  InheritableFoo {.inheritable.} = ref object
  InheritableBar = ref object of InheritableFoo # ERROR.

block: # bug #14698
  const N = 3
  type Foo[T] = ref object
    x1: int
    when N == 2:
      x2: float
    when N == 3:
      x3: seq[int]
    else:
      x4: char
      x4b: array[9, char]

  let t = Foo[float](x1: 1)
  doAssert $(t[]) == "(x1: 1, x3: @[])"
  doAssert t.sizeof == int.sizeof
  type Foo1 = object
    x1: int
    x3: seq[int]
  doAssert t[].sizeof == Foo1.sizeof
