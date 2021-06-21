discard """
  targets: "c js"
  joinable: false
"""

import std/os

var params = paramCount()
doAssert params == 0
doAssert paramStr(0).len > 0
doAssert commandLineParams().len == 0
