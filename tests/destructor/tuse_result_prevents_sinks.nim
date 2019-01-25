discard """
  output: ""
"""

# bug #9594

type
  Foo = object
    i: int

proc `=`(self: var Foo; other: Foo) =
  self.i = other.i + 1

proc `=sink`(self: var Foo; other: Foo) =
  self.i = other.i

proc `=destroy`(self: var Foo) = discard

proc test(): Foo =
  result = Foo()
  let temp = result
  doAssert temp.i > 0
  return result

proc testB(): Foo =
  result = Foo()
  let temp = result
  doAssert temp.i > 0

discard test()
discard testB()
