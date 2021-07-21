discard """
  errormsg: "type mismatch: obtained <ptr int16> expected 'ptr int'"
  line: 8
"""

var
  n: int16
  p: ptr int = addr n
