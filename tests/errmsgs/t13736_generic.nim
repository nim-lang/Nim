discard """
  errormsg: "cannot infer the return type of 'foo'"
  line: 6
"""

proc foo[T](x: T): auto =
  foo(x)

discard foo(1)
