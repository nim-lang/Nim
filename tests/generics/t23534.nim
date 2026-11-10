discard """
  output: '''
x is nil
true
true
'''
"""

# bug #23534 (and #16148): `nil` passed to `ptr T` before a later argument binds
# `T` left the generic `T` in the call: "internal error: getTypeDescAux(tyGenericParam)"

var x: ptr int

if nil == x:
  echo "x is nil"

proc same[T](a, b: ptr T): bool = a == b

echo same(nil, x)

proc first[T](a: ptr T, b: T): T = b

echo first(nil, 3) == 3
