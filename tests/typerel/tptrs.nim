discard """
  errormsg: "type mismatch: got 'ptr int16' for 'addr n', but expected 'ptr int'"
  line: 8
"""

var
  n: int16
  p: ptr int = addr n
