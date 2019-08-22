discard """
  errormsg: "ambiguous identifier"
  file: "tambsym3.nim"
  line: 11
"""
# Test ambiguous symbols

import mambsym1, times

var
  v = mDec #ERROR_MSG ambiguous identifier

writeLine(stdout, ord(v))
