discard """
errormsg: "invalid type: 'untyped' in this context: 'proc (a: varargs[untyped])' for proc"
line: 8
"""

import typetraits

proc foo(a:varargs[untyped]) =
  echo a[0].type.name

foo(1)

proc fool(): typed =
  discard

proc bar(): untyped =
  discard

proc foobar(x:typed) =
  discard

proc baz(y:untyped) =
  discard

proc barfaz(x: auto) =
  echo x

barfaz(123)
