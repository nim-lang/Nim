discard """
  output: '''
int
int
int
'''
"""

# bug #26374
import std/macros

type
  ValueObj[T] = object
    field: T

  RefObj[T] = ref object
    field: T

macro fieldType(T: typedesc): untyped =
  var impl = T.getTypeImpl[1].getTypeImpl
  if impl.kind == nnkRefTy:
    impl = impl[0].getTypeImpl
  newLit(impl[2][0][1].repr)

echo fieldType(ValueObj[int])
echo fieldType(RefObj[int])
echo fieldType typeof(default(RefObj[int])[])
