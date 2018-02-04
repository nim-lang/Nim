discard """
  output: '''int64
int64'''
"""

import typetraits

proc `@`[T: SomeInteger](x, y: T): T = x

echo(type(5'i64 @ 6'i32))

echo(type(5'i32 @ 6'i64))
