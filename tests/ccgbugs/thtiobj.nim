discard """
  targets: "c cpp"
"""

import typeinfo

var x = ""
discard (getPointer(toAny(x)))
