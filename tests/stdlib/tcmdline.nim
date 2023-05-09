discard """
  matrix: "--mm:refc; --mm:orc"
  targets: "c js"
  joinable: false
"""

import std/os
import std/assertions

var params = paramCount()
doAssert params == 0
doAssert paramStr(0).len > 0
doAssert commandLineParams().len == 0
