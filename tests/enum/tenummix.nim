discard """
  file: "system.nim"
  tline: 11
  errormsg: "type mismatch"
"""

type
  TE1 = enum eA, eB
  TE2 = enum eC, eD

doAssert eA != eC
