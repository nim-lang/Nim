discard """
  errormsg: "illegal recursion in type 'A'"
  line: 7
"""

type
  A = distinct A
