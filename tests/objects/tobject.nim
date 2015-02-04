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
