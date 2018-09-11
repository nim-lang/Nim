discard """
errormsg: "invalid type: 'untyped' in this context: 'proc (a: varargs[untyped])' for proc"
line: 8
"""

import typetraits

proc foo(a:varargs[untyped]) =
  echo a[0].type.name

foo(1)
