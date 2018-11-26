discard """
output: "20\n10"
nimout: '''
INFERRED int
VALUE TYPE int
VALUE TYPE NAME INT
IMPLICIT INFERRED int int
IMPLICIT VALUE TYPE int int
IMPLICIT VALUE TYPE NAME INT INT
'''
"""

import typetraits, strutils

template reject(e) =
  static: assert(not compiles(e))

type
  ArrayStack = object
    data: seq[int]

proc push(s: var ArrayStack, item: int) =
  s.data.add item

proc pop(s: var ArrayStack): int =
  return s.data.pop()

type
  Stack[T] = concept var s
    s.push(T)
    s.pop() is T

    type ValueType = T
    const ValueTypeName = T.name.toUpperAscii

proc genericAlgorithm[T](s: var Stack[T], y: T) =
  static:
    echo "INFERRED ", T.name
    echo "VALUE TYPE ", s.ValueType.name
    echo "VALUE TYPE NAME ", s.ValueTypeName

  s.push(y)
  echo s.pop

proc implicitGeneric(s: var Stack): auto =
  static:
    echo "IMPLICIT INFERRED ", s.T.name, " ", Stack.T.name
    echo "IMPLICIT VALUE TYPE ", s.ValueType.name, " ", Stack.ValueType.name
    echo "IMPLICIT VALUE TYPE NAME ", s.ValueTypeName, " ", Stack.ValueTypeName

  return s.pop()

var s = ArrayStack(data: @[])

s.push 10
s.genericAlgorithm 20
echo s.implicitGeneric

reject s.genericAlgorithm "x"
reject s.genericAlgorithm 1.0
reject "str".implicitGeneric
reject implicitGeneric(10)
