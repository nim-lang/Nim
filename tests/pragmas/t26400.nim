discard """
  output: '''
true
true
true
true
nnkObjectTy
nnkObjectTy
Generic[int]
Generic[system.int]
'''
"""

# bug #26400: `hasCustomPragma` looped for a field of a `typeof` alias of a
#   generic instance
# bug #26401: `hasCustomPragma` returned false for a field of a plain alias of
#   a generic instance
# bug #26412: `getTypeImpl` returned a symbol for a `typeof` alias of a
#   generic instance

import std/macros

template myPragma {.pragma.}
template val(x: int) {.pragma.}

type
  Generic[T] = object
    field {.myPragma.}: T
    v {.val(4).}: int
  Alias = typeof(Generic[int]())
  PlainAlias = Generic[int]

var c: Alias
echo c.field.hasCustomPragma(myPragma)
echo PlainAlias().field.hasCustomPragma(myPragma)
echo Generic[int]().field.hasCustomPragma(myPragma)
echo c.v.getCustomPragmaVal(val) == 4

macro declImpl(T: type): untyped =
  newLit($T.getTypeInst[1].getImpl[0].getTypeInst.getTypeImpl.kind)

echo declImpl(Alias)
echo declImpl(PlainAlias)

# the shared generic instance must not be renamed to `Alias`:
macro instName(x: typed): untyped =
  newLit(repr(x.getTypeInst))

var g: Generic[int]
echo instName(g)
echo $typeof(g)
