discard """
  matrix: "--mm:refc"
  targets: "c cpp"
"""

import typeinfo

var x = ""
discard (getPointer(toAny(x)))
