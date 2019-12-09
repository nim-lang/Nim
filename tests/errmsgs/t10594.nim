discard """
  errormsg: "expression has no address"
  line: 7
"""

template foo(v: varargs[int]) = unsafeAddr v 
foo(1, 2)
