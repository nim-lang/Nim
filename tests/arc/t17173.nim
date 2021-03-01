discard """
  cmd: "nim c -r --gc:arc $file"
"""

import std/strbasics


var a = "  vhellov   "
strip(a)
doAssert a == "vhellov"
