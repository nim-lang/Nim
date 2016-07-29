discard """
output: "20\n10"
msg: '''
INFERRED int
IMPLICIT INFERRED int int
'''
"""

import typetraits

template reject(e: expr) =
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

proc genericAlgorithm[T](s: var Stack[T], y: T) =
  static: echo "INFERRED ", T.name

  s.push(y)
  echo s.pop

proc implicitGeneric(s: var Stack): auto =
  static: echo "IMPLICIT INFERRED ", s.T.name, " ", Stack.T.name

  return s.pop()

var s = ArrayStack(data: @[])

s.push 10
s.genericAlgorithm 20
echo s.implicitGeneric

reject s.genericAlgorithm "x"
reject s.genericAlgorithm 1.0
reject "str".implicitGeneric
reject implicitGeneric(10)

