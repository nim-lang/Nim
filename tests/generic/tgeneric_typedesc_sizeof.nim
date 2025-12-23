discard """
  output: '''
42
'''
"""

# Regression test for semtypinst.nim hasValuelessStatics bug.
#
# Bug: hasValuelessStatics only checked for tyStatic, missing tyTypeDesc(tyGenericParam)
# Fix: Added check for tyTypeDesc wrapping tyGenericParam in compiler/semtypinst.nim
#
# The bug triggers when:
# 1. A generic type has a when clause calling a typedesc template with sizeof(T)
# 2. A generic proc on that type is called, triggering instantiation
# 3. The T in sizeof(T) becomes tyTypeDesc(tyGenericParam), which wasn't recognized as unresolved
#
# Error without fix: 'sizeof' requires '.importc' types to be '.completeStruct'

template isSmall(T: typedesc): bool =
  sizeof(T) <= 8

type Foo[T] = object
  when isSmall(T):
    a: T
  else:
    b: ptr T

proc bar[T](x: var Foo[T]) =
  discard

var x: Foo[int]
x.a = 42
x.bar()
echo x.a
