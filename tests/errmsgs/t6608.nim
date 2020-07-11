discard """
  errormsg: " Error: type mismatch: got <>
but expected one of:
AcceptCB = proc (s: string){.closure.}"
  line: 12
"""

type
  AcceptCB = proc (s: string)

proc x(x: AcceptCB) =
  x()

x()
