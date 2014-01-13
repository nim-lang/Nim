discard """
  file: "typredef.nim"
  line: 7
  errormsg: "illegal recursion in type \'Uint8\'"
"""
type
  Uint8 = Uint8 #ERROR_MSG illegal recursion in type 'Uint8'

