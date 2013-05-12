discard """
  file: "tstmtexp.nim"
  line: 8
  errormsg: "value returned by statement has to be discarded"
"""
# Test 3

1+4 #ERROR_MSG value returned by statement has to be discarded

