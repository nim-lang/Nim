discard """
  errormsg: "ambiguous enum field"
  file: "tambsym3.nim"
  line: 14
"""
# Test ambiguous symbols

import mambsym1, times

{.hint[AmbiguousEnum]: on.}
{.hintAsError[AmbiguousEnum]: on.}

var
  v = mDec #ERROR_MSG ambiguous identifier

writeLine(stdout, ord(v))
