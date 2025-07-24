discard """
  output: '''
5
'''
"""

proc foo(a, b: int) =
  echo a + b

foo a = 2, b = 3

import macros

macro bar(args: varargs[untyped]): untyped =
  doAssert args[0].kind == nnkExprEqExpr

bar "a" = 1
