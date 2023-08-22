discard """
  errormsg: "illegal recursion in type \'Uint8\'"
  file: "typredef.nim"
  line: 7
"""
type
  Uint8 = Uint8 #ERROR_MSG illegal recursion in type 'Uint8'
