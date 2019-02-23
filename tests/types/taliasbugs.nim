discard """
  nimout: '''true
true
true
true
true
true'''
  output: '''true
true
true
true
true
true
R
R
R
R
19
(c: 0)
(c: 13)
@[(c: 11)]
@[(c: 17)]
100'''
"""

# bug #5360
import macros

type
  Order = enum
    R
  OrderAlias = Order

template getOrderTypeA(): typedesc = Order
template getOrderTypeB(): typedesc = OrderAlias

type
  OrderR    = getOrderTypeA()
  OrderG    = getOrderTypeB()

macro typeRep(a, b: typed): untyped =
  if sameType(a, b):
    echo "true"
  else:
    echo "false"

template test(a, b: typedesc) =
  when a is b:
    echo "true"
  else:
    echo "false"

test(OrderAlias, Order)
test(OrderR, Order)
test(OrderG, Order)

test(OrderR, OrderG)
test(OrderR, OrderAlias)
test(OrderG, OrderAlias)

typeRep(OrderAlias.R, Order.R)  # true
typeRep(OrderR.R, Order.R)      # true
typeRep(OrderG.R, Order.R)      # true

typeRep(OrderR.R, OrderAlias.R) # true
typeRep(OrderG.R, OrderAlias.R) # true
typeRep(OrderR.R, OrderG.R)     # true

echo OrderR.R      # R
echo OrderG.R      # R
echo OrderAlias.R  # R
echo Order.R       # R

# bug #5238

type
  Rgba8 = object
    c: int
  BlenderRgb*[ColorT] = object

template getColorType*[C](x: typedesc[BlenderRgb[C]]): typedesc = C

type
  ColorT = getColorType(BlenderRgb[int])

proc setColor(c: var ColorT) =
  c = 19

var n: ColorT
n.setColor()
echo n

type
  ColorType = getColorType(BlenderRgb[Rgba8])

var x: ColorType
echo x

proc setColor(c: var ColorType) =
  c = Rgba8(c: 13)

proc setColor(c: var seq[ColorType]) =
  c[0] = Rgba8(c: 11)

proc setColorArray(c: var openArray[ColorType]) =
  c[0] = Rgba8(c: 17)

x.setColor()
echo x

var y = @[Rgba8(c:15)]
y.setColor()
echo y

y.setColorArray()
echo y

#bug #6016
type
  Onion {.union.} = object
    field1: int
    field2: uint64

  Stroom  = Onion

  PStroom = ptr Stroom

proc pstruct(u: PStroom) =
  echo u.field2

var oni = Onion(field1: 100)
pstruct(oni.addr)


# bug #4124

import sequtils

type
    Foo = distinct string

var
  foo: Foo

type
    Alias = (type(foo))
var
  a: Alias

a = foo

when true:
  var xs = @[1,2,3]

  proc asFoo(i: string): Foo =
      Foo(i)

  var xx = xs.mapIt(asFoo($(it + 5)))


block t4674:
  type
    FooObj[T] = object
      v: T
    Foo1[T] = FooObj[T]
    Foo2 = FooObj
    Foo1x = Foo1
    Foo12x = Foo1 | Foo2
    Foo2x = Foo2  # Error: illegal recursion in type 'Foo2x'
