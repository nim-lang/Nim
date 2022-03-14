discard """
  matrix: "--gc:refc; --gc:arc"
"""

import std/strbasics
import std/assertions


var a = "  vhellov   "
strip(a)
doAssert a == "vhellov"
