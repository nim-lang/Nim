discard """
  matrix: "--gc:refc; --gc:arc; --newruntime"
"""

import std/strbasics


var a = "  vhellov   "
strip(a)
doAssert a == "vhellov"
