discard """
  action: run
"""

type T = object
  x: int
  s: string

var obj: T
var fieldAddr = addr(obj.x)
var objAddr = addr(obj)

# Integer tests
var field = fieldAddr[]
doAssert field == 0

var objDeref = objAddr[]
doAssert objDeref.x == 0

# Change value
obj.x = 42

doAssert field == 0
doAssert objDeref.x == 0

field = fieldAddr[]
objDeref = objAddr[]

doAssert field == 42
doAssert objDeref.x == 42

# String tests
obj.s = "lorem ipsum dolor sit amet"
var indexAddr = addr(obj.s[2])

doAssert indexAddr[] == 'r'

indexAddr[] = 'd'

doAssert indexAddr[] == 'd'

doAssert obj.s == "lodem ipsum dolor sit amet"

# Bug #2148
var x: array[2, int]
var y = addr x[1]

y[] = 12
doAssert(x[1] == 12)

type
  Foo = object
    bar: int

var foo: array[2, Foo]
var z = addr foo[1]

z[].bar = 12345
doAssert(foo[1].bar == 12345)

var t : tuple[a, b: int]
var pt = addr t[1]
pt[] = 123
doAssert(t.b == 123)

#block: # Test "untyped" pointer.
proc testPtr(p: pointer, a: int) =
  doAssert(a == 5)
  (cast[ptr int](p))[] = 124
var i = 123
testPtr(addr i, 5)
doAssert(i == 124)

var someGlobal = 5
proc getSomeGlobalPtr(): ptr int = addr someGlobal
let someGlobalPtr = getSomeGlobalPtr()
doAssert(someGlobalPtr[] == 5)
someGlobalPtr[] = 10
doAssert(someGlobal == 10)
