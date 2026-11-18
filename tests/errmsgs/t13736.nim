discard """
  errormsg: "cannot infer the return type of 'foo': it is called recursively before a 'return' or 'result' assignment determines it"
  line: 9
"""

# bug #13736: used to crash the compiler
proc foo(n: int): auto =
  if n < 5:
    return foo(n + 1)
  else:
    return 9

echo foo(3)
