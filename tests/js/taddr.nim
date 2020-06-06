discard """
  targets: "c js"
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

block:
  # issue #14576
  # lots of these used to give: Error: internal error: genAddr: 2
  proc byLent[T](a: T): lent T = a
  proc byPtr[T](a: T): ptr T = a.unsafeAddr

  block:
    let a = (10,11)
    let (x,y) = byLent(a)
    doAssert (x,y) == a

  block:
    when defined(c) and defined(release):
      # bug; pending https://github.com/nim-lang/Nim/issues/14578
      discard
    else:
      let a = 10
      doAssert byLent(a) == 10
      let a2 = byLent(a)
      doAssert a2 == 10

  block:
    let a = [11,12]
    doAssert byLent(a) == [11,12]
    let a2 = (11,)
    doAssert byLent(a2) == (11,)

  block:
    when defined(c) and defined(release):
      discard # probably not a bug since optimizer is free to pass by value, and `unsafeAddr` is used
    else:
      var a = @[12]
      doAssert byPtr(a)[] == @[12]
      let a2 = [13]
      doAssert byPtr(a2)[] == [13]
      let a3 = 14
      doAssert byPtr(a3)[] == 14

  block:
    proc byLent2[T](a: seq[T]): lent T = a[1]
    var a = @[20,21,22]
    doAssert byLent2(a) == 21

  block: # sanity checks
    proc bar[T](a: var T): var T = a
    var a = (10, 11)
    let (k,v) = bar(a)
    doAssert (k, v) == a
    doAssert k == 10
    bar(a)[0]+=100
    doAssert a == (110, 11)
    var a2 = 12
    doAssert bar(a2) == a2
    bar(a2).inc
    doAssert a2 == 13

  block: # xxx: bug this doesn't work
    when false:
      proc byLent2[T](a: T): lent type(a[0]) = a[0]
