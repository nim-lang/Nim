discard """
cmd: "nim check $file"
errormsg: "not all cases are covered; missing: {A, B}"
nimout: '''
tincompletecaseobject2.nim(16, 1) Error: not all cases are covered; missing: {B, C, D}
tincompletecaseobject2.nim(19, 1) Error: not all cases are covered; missing: {A, C}
tincompletecaseobject2.nim(22, 1) Error: not all cases are covered; missing: {A, B}
'''
"""
type
  ABCD = enum A, B, C, D
  AliasABCD = ABCD
  RangeABC = range[A .. C]
  AliasRangeABC = RangeABC

case AliasABCD A:
of A: discard

case RangeABC A:
of B: discard

case AliasRangeABC A:
of C: discard
