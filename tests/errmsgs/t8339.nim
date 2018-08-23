discard """
  line: 8
  errormsg: "type mismatch: got <seq[int]> but expected 'seq[float]'"
"""

import sequtils

var x: seq[float] = @[1].mapIt(it)
