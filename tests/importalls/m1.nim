import ./m2
import ./m3 {.all.} as m3
from ./m3 as m3Bis import nil

doAssert m3h2 == 2
export m3h2

export m3Bis.m3p1

const foo0* = 2
const foo1 = bar1

const foo1Aux = 2
export foo1Aux

doAssert not declared(bar2)
doAssert not compiles(bar2)

var foo2 = 2
let foo3 = 2

type Foo4 = enum
  kg1, kg2

type Foo4b {.pure.} = enum
  foo4b1, foo4b2

type Foo5 = object
  z1: string
  z2: Foo4
  z3: int
  z4*: int

proc `z3`*(a: Foo5): auto =
  a.z3 * 10

proc foo6(): auto = 2
proc foo6b*(): auto = 2
template foo7: untyped = 2
macro foo8(): untyped = discard
template foo9(a: int) = discard

block:
  template foo10: untyped = 2
  type Foo11 = enum
    kg1b, kg2b
  proc foo12(): auto = 2

proc initFoo5*(z3: int): Foo5 = Foo5(z3: z3)

func foo13(): auto = 2
iterator foo14a(): int = discard
iterator foo14b*(): int = discard
iterator foo14c(): int {.closure.} = discard
iterator foo14d(): int {.inline.} = discard

# fwd declare
proc foo15(): int
proc foo15(): int = 2

proc foo16*(): int
proc foo16(): int = 2

proc foo17*(): int
proc foo17*(): int = 2

# other
type A1 = distinct int
type A2 = distinct int
converter foo18(x: A1): A2 = discard
