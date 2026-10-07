discard """
  output: '''
K[t26368.V]
K[t26368.V]
'''
"""

# bug #26368
import std/macros

type
  K[T] = seq[T]
  M = object
    l: K[V]
  V = object
    x: int

macro instRepr(x: typed): string =
  newLit(x.getTypeInst.repr)

static: doAssert instRepr(M().l) == "K[V]"
echo $typeof(M().l)
const s = $typeof(M().l)
echo s
