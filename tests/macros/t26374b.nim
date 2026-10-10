discard """
  output: '''
nnkObjectTy
'''
"""

# getTypeInst/getTypeImpl through the name node of a `typeof` type alias
# (regression in stew's test_macros)
import std/macros

type
  PublicBaseType[T] = object of RootObj
    pubBaseField*: T
  TypeofGenericType = typeof(PublicBaseType[int]())

macro m(T: type): untyped =
  let typ = T.getTypeInst[1]
  let name = typ.getImpl[0]
  result = newLit($name.getTypeInst.getTypeImpl.kind)

echo m(TypeofGenericType)
