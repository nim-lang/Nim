discard """
  line: 8
  errormsg: "invalid type"
"""
# Tests a special bug

var
  x: ref openarray[string] #ERROR_MSG invalid type
