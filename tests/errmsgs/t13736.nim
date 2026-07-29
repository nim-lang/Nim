discard """
  errormsg: "cannot infer type of recursive call"
  line: 8
"""

proc foo(n: int): auto =
  if n < 5:
    return foo(n + 1)
  else:
    return 9

echo foo(3)
