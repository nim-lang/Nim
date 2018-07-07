discard """
  output: '''false'''
"""

when false:
  import typetraits

  proc `@`[T: SomeInteger](x, y: T): T = x

  echo(type(5'i64 @ 6'i32))

  echo(type(5'i32 @ 6'i64))

import sets
# bug #7247
type
  n8 = range[0'i8..127'i8]

var tab = initSet[n8]()

echo tab.contains(8)
