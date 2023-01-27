discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''(x: "string here", a: 1)
b is 5
x is 12'''
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

# bug #11958
proc foo() =
  var a = 5
  proc bar() {.nimcall.} =
    var b = 5
    for k, v in fieldpairs(locals()):
      echo k, " is ", v

  bar()
foo()


proc foo2() =
  var a = 5
  proc bar2() {.nimcall.} =
    for k, v in fieldpairs(locals()):
      echo k, " is ", v

  bar2()
foo2()


proc foo3[T](y: T) =
  var a = 5
  proc bar2[T](x: T) {.nimcall.} =
    for k, v in fieldpairs(locals()):
      echo k, " is ", v

  bar2(y)

foo3(12)

block: # bug #12682
  template foo(): untyped =
    var c1 = locals()
    1

  proc testAll()=
    doAssert foo() == 1
    let c2=locals()

  testAll()
