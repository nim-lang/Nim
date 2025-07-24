discard """
  errormsg: "illegal recursion in type 'x'"
"""

type x = distinct x
