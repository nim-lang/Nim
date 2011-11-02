discard """
  file: "tmissingnl.nim"
  line: 7
  errormsg: "newline expected, but found 'keyword var'"
"""

import strutils var s: seq[int] = @[0, 1, 2, 3, 4, 5, 6]

#s[1..3] = @[]

