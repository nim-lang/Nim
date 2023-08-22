discard """
output: '''type(c) = GenAlias[system.int]
T = int
seq[int]
'''
"""

import typetraits

type
  Gen[T] = object
    x: T

  GenAlias[T] = Gen[seq[T]]

proc f1[T](x: Gen[T]) =
  echo T.name

proc f2[T](x: GenAlias[T]) =
  echo "type(c) = ", type(x).name
  echo "T = ", T.name
  f1 x

let
  y = Gen[seq[int]](x: @[10])

f2 y

