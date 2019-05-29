discard """
  errormsg: "type mismatch: got <seq[int]> but expected 'tuple of (int, int)'"
  line: 8
"""
var
  a = 1
  b = 2
(a, b) = @[3, 4]
