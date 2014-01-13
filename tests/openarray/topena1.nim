discard """
  file: "topena1.nim"
  line: 9
  errormsg: "invalid type"
"""
# Tests a special bug

var
  x: ref openarray[string] #ERROR_MSG invalid type



