discard """
  errormsg: "ambiguous enum field"
  file: "tambsym3.nim"
  line: 13
"""
# Test ambiguous symbols

import mambsym1, times

{.warningAsError[AmbiguousEnum]: on.}

var
  v = mDec #ERROR_MSG ambiguous identifier

writeLine(stdout, ord(v))
