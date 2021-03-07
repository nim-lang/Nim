discard """
  matrix: "--gc:refc; --gc:arc"
"""

import std/strbasics


var a = "  vhellov   "
strip(a)
doAssert a == "vhellov"
