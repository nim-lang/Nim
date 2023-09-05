discard """
  output: '''4887 true
0.5'''
"""

# test the new borrow feature that works with generics:

proc `++`*[T: int | float](a, b: T): T =
  result = a + b

type
  DI = distinct int
  DF = distinct float
  DS = distinct string

proc `++`(x, y: DI): DI {.borrow.}
proc `++`(x, y: DF): DF {.borrow.}

proc `$`(x: DI): string {.borrow.}
proc `$`(x: DF): string {.borrow.}

echo  4544.DI ++ 343.DI, " ", (4.5.DF ++ 0.5.DF).float == 5.0

# issue #14440

type Radians = distinct float64

func `-=`(a: var Radians, b: Radians) {.borrow.}

var a = Radians(1.5)
let b = Radians(1.0)

a -= b

echo a.float64

block: #14449
  type 
    Foo[T] = object
      foo: T

    Bar[T] {.borrow:`.`.} = distinct Foo[T]
    SomeThing {.borrow:`.`.} = distinct Foo[float]
    OtherThing {.borrow:`.`.} = distinct SomeThing

  var
    a: Bar[int]
    b: SomeThing
    c: OtherThing
  a.foo = 300
  b.foo = 400
  c.foo = 42
  assert a.foo == 300
  assert b.foo == 400d
  assert c.foo == 42d

block: # Borrow from muliple aliasses #16666
  type
    AImpl = object
      i: int
    
    A = AImpl
  
    B {.borrow: `.`.} = distinct A
    C = B
    D {.borrow: `.`.} = distinct C
    E {.borrow: `.`.} = distinct D
  
  let
    b = default(B)
    d = default(D)
    e = default(E)
  
  assert b.i == 0
  assert d.i == 0
  assert e.i == 0

block: # Borrow from generic alias
  type
    AImpl[T] = object
      i: T
    B[T] = AImpl[T]
    C {.borrow: `.`.} = distinct B[int]
    D = B[float]
    E {.borrow: `.`.} = distinct D

  let
    c = default(C)
    e = default(E)
  assert c.i == int(0)
  assert e.i == 0d

block: # issue #22069
  type
    Vehicle[C: static[int]] = object
      color: array[C, int]
    Car[C: static[int]] {.borrow: `.`.} = distinct Vehicle[C]
    MuscleCar = Car[128]
  var x: MuscleCar
  doAssert x.color is array[128, int]

block: # issue #22646
  type
    Vec[N : static[int], T: SomeNumber] = object
      arr: array[N, T]
    Vec3[T: SomeNumber] = Vec[3, T]

  proc `[]=`[N,T](v: var Vec[N,T]; ix:int; c:T): void {.inline.} = v.arr[ix] = c
  proc `[]`[N,T](v: Vec[N,T]; ix: int): T {.inline.} = v.arr[ix]

  proc dot[N,T](u,v: Vec[N,T]): T {. inline .} = discard
  proc length[N,T](v: Vec[N,T]): T = discard
  proc cross[T](v1,v2:Vec[3,T]): Vec[3,T] = discard
  proc normalizeWorks[T](v: Vec[3,T]): Vec[3,T] = discard ## <- Explicit size makes it work!
  proc foo[N,T](u, v: Vec[N,T]): Vec[N,T] = discard ## <- broken
  proc normalize[N,T](v: Vec[N,T]): Vec[N,T] = discard ## <- broken

  type Color = distinct Vec3[float]

  template borrowOps(typ: typedesc): untyped =
    proc `[]=`(v: var typ; ix: int; c: float): void {.borrow.}
    proc `[]`(v: typ; ix: int): float {.borrow.}
    proc dot(v, u: typ): float {.borrow.}
    proc cross(v, u: typ): typ {.borrow.}
    proc length(v: typ): float {.borrow.}
    proc normalizeWorks(v: typ): typ {.borrow.} ## Up to here everything works
    proc foo(u, v: typ): typ {.borrow.} ## Broken
    proc normalize(v: typ): typ {.borrow.} ## Broken
  borrowOps(Color)
  var x: Vec[3, float]
  let y = Color(x)
  doAssert Vec3[float](y) == x
