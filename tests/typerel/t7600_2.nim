discard """
errormsg: "type mismatch: got <Thin>"
nimout: '''t7600_2.nim(17, 6) Error: type mismatch: got <Thin>
but expected one of:
proc test(x: Paper)

expression: test tn'''
"""

type
  Paper = ref object of RootObj
  Thin  = object of Paper

proc test(x: Paper) = discard

var tn = Thin()
test tn
