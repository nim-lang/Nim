discard """
  output: '''
K[t26368.V]
K[t26368.V]
A O D P Option[t26368.Foo]
'''
"""

# bug #26368
import std/[macros, options]

type
  K[T] = seq[T]
  M = object
    l: K[V]
  A = K[V]
  O = Option[V]
  Foo = ref object
    x: Option[Foo]
    y: A
  D = distinct K[V]
  P = ref K[V]
  V = object
    x: int

macro instRepr(x: typed): string =
  newLit(x.getTypeInst.repr)

static:
  doAssert instRepr(M().l) == "K[V]"
  doAssert instRepr(Foo().x) == "Option[Foo]"
  doAssert instRepr(Foo().y) == "A"
echo $typeof(M().l)
const s = $typeof(M().l)
echo s
echo $A, " ", $O, " ", $D, " ", $P, " ", $typeof(Foo().x)
doAssert A is K[V]
var a: A = @[V(x: 1)]
doAssert a.len == 1
doAssert O.default.isNone
