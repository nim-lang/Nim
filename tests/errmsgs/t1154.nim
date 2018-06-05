discard """
errormsg: "invalid type: 'expr' in this context: 'proc (a: varargs[expr])' for proc"
line: 8
"""

import typetraits

proc foo(a:varargs[expr]) =
  echo a[0].type.name

foo(1)
