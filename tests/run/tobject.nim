import unittest

type Obj = object
  foo: int

proc makeObj(x: int): ref Obj = 
  new(result)
  result.foo = x

proc initObj(x: int): Obj = 
  result.foo = x

template stringTest(init: expr) =
  test "it should convert an object to a string":
    var obj = `init`(1)
    # Should be "obj: (foo: 1)" or similar.
    check($obj == "(foo: 1)")

suite "object basic methods":
  suite "ref":
    stringTest(makeObj)
  suite "value":
    stringTest(initObj)
    test "it should test equality based on fields":
      check(initObj(1) == initObj(1))
