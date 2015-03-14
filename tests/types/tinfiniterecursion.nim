discard """
  errormsg: "illegal recursion in type 'XIM'"
  line: 8
"""

type
  XIM* = ptr XIM
  XIMProc* = proc (a2: XIM)
