discard """
  errormsg: '''errmsgs/t6608.nim(12, 4) Error: type mismatch: got <>
but expected one of: 
AcceptCB = proc (s: string){.closure.}'''
  line: 12
"""

type
  AcceptCB = proc (s: string)

proc x(x: AcceptCB) =
  x()

x()
