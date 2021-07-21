discard """
  errormsg: "type mismatch: obtained <seq[int]> expected 'seq[float]'"
  line: 8
"""

import sequtils

var x: seq[float] = @[1].mapIt(it)
