discard """
output: "[Suite] object basic methods"
"""

import unittest

type Obj = object
  foo: int

proc makeObj(x: int): Obj =
  result.foo = x

suite "object basic methods":
  test "it should convert an object to a string":
    var obj = makeObj(1)
    # Should be "obj: (foo: 1)" or similar.
    check($obj == "(foo: 1)")
  test "it should test equality based on fields":
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
