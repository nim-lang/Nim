discard """
  line: 10
  errormsg: "ambiguous identifier"
"""
# Test ambiguous symbols

import mambsym1, times

var
  v = mDec #ERROR_MSG ambiguous identifier

writeLine(stdout, ord(v))
