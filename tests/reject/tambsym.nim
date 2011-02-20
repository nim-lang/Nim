discard """
  file: "tambsym.nim"
  line: 11
  errormsg: "ambiguous identifier"
"""
# Test ambiguous symbols

import mambsym1, mambsym2

var
  v: TExport #ERROR_MSG ambiguous identifier

v = y


