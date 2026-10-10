discard """
  errormsg: "cannot infer the return type of 'foo'"
  line: 6
"""

proc foo(n: int): auto =
  return foo(n + 1)

discard foo(0)
