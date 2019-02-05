discard """
  errormsg: "type mismatch"
  line: 10
"""

type
  TE1 = enum eA, eB
  TE2 = enum eC, eD

assert eA != eC
