discard """
output: '''7'''
"""

# Regression: concept matching against a NIF-loaded type must load the
# Partial tyTypeDesc before skipping it in typeRel.skipTypeCursor.

import mtypeclass

type HasX = concept v
  v.x is int

proc use*[T: HasX](v: T): int = v.x

echo use(Foo(x: 7))
