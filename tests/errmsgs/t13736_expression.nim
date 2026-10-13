discard """
  errormsg: "cannot infer the return type of 'foo'"
  line: 6
"""

proc foo(n: int): auto =
  if n > 0:
    foo(n - 1)
  else:
    foo(n + 1)

discard foo(1)
