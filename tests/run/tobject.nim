import unittest

type Obj = object
  foo: int

proc makeObj(x: int): ref Obj = 
  new(result)
  result.foo = x

proc initObject(x: int): Obj = 
  result.foo = x

suite "object basic methods":
  test "it should convert an objcet to a string":
    var obj = makeObj(1)
    # Should be "obj: (foo: 1)" or similar.
    check($obj == "(foo: 1)")
  test "it should test equality based on fields":
    check(initObj(1) == initObj(1))
  test "it should test equality based on fields for refs too":
    check(makeObj(1) == makeObj(1))
