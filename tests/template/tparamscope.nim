discard """
  errormsg: "undeclared identifier: 'a'"
  line: 10
"""


template secondArg(a, b: typed): untyped =
  b

echo secondArg((var a = 1; 1), a)
