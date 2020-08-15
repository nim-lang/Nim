discard """
  cmd: "nim c --hints:off $file"
  errormsg: "type mismatch: got <>"
  nimout: '''t6608.nim(14, 4) Error: type mismatch: got <>
but expected one of:
AcceptCB = proc (s: string){.closure.}'''
  line: 14
"""

type
  AcceptCB = proc (s: string)

proc x(x: AcceptCB) =
  x()

x()
