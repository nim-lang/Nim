discard """
  output: '''(x: "string here", a: 1)'''
"""

proc simple[T](a: T) =
  var
    x = "string here"
  echo locals()

simple(1)

type Foo2[T]=object
  a2: T

proc numFields*(T: typedesc[tuple|object]): int=
  var t:T
  for _ in t.fields: inc result

proc test(baz: int, qux: var int): int =
  var foo: Foo2[int]
  let bar = "abc"
  let c1 = locals()
  doAssert numFields(c1.foo.type) == 1
  doAssert c1.bar == "abc"
  doAssert c1.baz == 123
  doAssert c1.result == 0
  doAssert c1.qux == 456

var x1 = 456
discard test(123, x1)
