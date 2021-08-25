discard """
  errormsg: "type mismatch: got 'seq[int]' for '"
  line: 8
"""

import sequtils

var x: seq[float] = @[1].mapIt(it)
