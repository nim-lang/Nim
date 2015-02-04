discard """
  file: "tambsym3.nim"
  line: 11
  errormsg: "ambiguous identifier"
"""
# Test ambiguous symbols

import mambsym1, times

var
  v = mDec #ERROR_MSG ambiguous identifier

writeln(stdout, ord(v))


