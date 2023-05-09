discard """
  errormsg: "illegal recursion in type 'A'"
"""

type
  A* = A
  B = (A,)
