discard """
  output: '''0
0
'''
"""

import macros

macro varargsLen(args:varargs[untyped]): untyped =
  doAssert args.kind == nnkArglist
  doAssert args.len == 0
  result = newLit(args.len)

template bar(a0:varargs[untyped]): untyped =
  varargsLen(a0)

template foo(x: int, a0:varargs[untyped]): untyped =
  bar(a0)

echo foo(42)
echo bar()
