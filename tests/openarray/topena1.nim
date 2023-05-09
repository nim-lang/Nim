discard """
  errormsg: "invalid type"
  file: "topena1.nim"
  line: 9
"""
# Tests a special bug

var
  x: ref openArray[string] #ERROR_MSG invalid type
