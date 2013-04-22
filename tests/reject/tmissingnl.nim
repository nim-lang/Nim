discard """
  file: "tmissingnl.nim"
  line: 7
  errormsg: "invalid indentation"
"""

import strutils var s: seq[int] = @[0, 1, 2, 3, 4, 5, 6]

#s[1..3] = @[]

