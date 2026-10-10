discard """
  errormsg: "the field 'secret' is not accessible."
  line: 10
"""

import msumtypes

proc sec(h: Hidden): int =
  case h
  of H1(s): s
  of H2(): 0
