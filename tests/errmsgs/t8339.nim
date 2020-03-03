discard """
  errormsg: "type mismatch: got <seq[int]> but expected 'seq[float]'"
  line: 8
"""

import sequtils

var x: seq[float] = @[1].mapIt(it)
