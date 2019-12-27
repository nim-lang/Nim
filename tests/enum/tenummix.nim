discard """
  errormsg: "type mismatch"
  file: "tenummix.nim"
  line: 11
"""

type
  TE1 = enum eA, eB
  TE2 = enum eC, eD

assert eA != eC
