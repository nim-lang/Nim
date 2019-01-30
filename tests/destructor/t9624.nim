discard """
  exitcode: 0
  output: ""
"""

type Foo = object
  b: bool

var i: int

proc `=`(self: var Foo; other: Foo) =
  if self.b:
    dec i
  if other.b:
    inc i
  self.b = other.b

proc `=destroy`(self: var Foo) =
  if self.b:
    dec i
    self.b = false

proc `=sink`(self: var Foo; other: Foo) =
  `=destroy`(self)
  self.b = other.b

proc testTuple(): Foo =
  let a = Foo(b: true)
  let b = (a, a) # first `a` is copied, second `a` is moved
  let c = b
  return c[1]

i = 0
let x = testTuple()
doAssert i == 0 

proc testArray(): Foo =
  let a = Foo(b: true)
  let b = [a, a]  # first `a` is copied, second `a` is moved
  return b[1]

i = 0
let y = testArray()
doAssert i == 0 # -2

proc testSeq(): Foo =
  let a = Foo(b: true)
  let b = @[a, a]  # first `a` is copied, second `a` is moved
  return b[1]

i = 0
let z = testSeq()
doAssert i == 0