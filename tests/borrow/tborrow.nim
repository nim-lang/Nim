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