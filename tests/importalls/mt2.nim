from ./m1 {.all.} as r1 import foo1
from ./m1 {.all.} as r2 import foo7

block: # different symbol kinds
  doAssert foo1 == 2
  doAssert r1.foo1 == 2
  doAssert r1.foo2 == 2
  doAssert compiles(foo1)
  doAssert compiles(r1.foo2)
  doAssert not compiles(foo2)
  doAssert not compiles(m3h2)
  doAssert r1.foo3 == 2

  block: # enum
    # r1.kg1
    var a: r1.Foo4
    let a1 = r1.kg1
    doAssert a1 == r1.Foo4.kg1
    type Foo4b = r1.Foo4
    doAssert a1 == Foo4b.kg1
    doAssert not compiles(kg1)
    doAssert compiles(Foo4b.kg1)
    var witness = false
    for ai in r1.Foo4:
      doAssert ai == a
      doAssert ai == a1
      witness = true
      break
    doAssert witness

  block: # object
    doAssert compiles(r1.Foo5)
    var a: r1.Foo5
    doAssert compiles(a.z4)
    doAssert not compiles(a.z3)

  # remaining symbol kinds
  doAssert r1.foo6() == 2
  doAssert r1.foo6b() == 2
  doAssert foo7() == 2
  doAssert r2.foo6b() == 2

  r1.foo8()
  r1.foo9(1)
  doAssert r1.foo13() == 2
  for a in r1.foo14a(): discard
  for a in r1.foo14b(): discard
  for a in r1.foo14c(): discard
  for a in r1.foo14d(): discard

  # should not be visible
  doAssert not compiles(foo10())
  doAssert not compiles(r1.Foo11)
  doAssert not compiles(r1.kg1b)
  doAssert not compiles(r1.foo12())

## field access
import std/importutils
privateAccess(r1.Foo5)
var x = r1.Foo5(z1: "foo", z2: r1.kg1)
doAssert x.z1 == "foo"

var f0: r1.Foo5
f0.z3 = 3
doAssert f0.z3 == 3
var f = r1.initFoo5(z3=3)
doAssert f.z3 == 3
doAssert r1.z3(f) == 30

import ./m1 as r3
doAssert not declared(foo2)
doAssert not declared(r3.foo2)

from ./m1 {.all.} as r4 import nil
doAssert not declared(foo2)
doAssert declared(r4.foo2)

from ./m1 {.all.} import nil
doAssert not declared(foo2)
doAssert declared(m1.foo2)
