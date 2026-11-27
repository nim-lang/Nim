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

block: # control characters do not make `parseCmdLine` loop forever
  when not defined(windows):
    doAssert parseCmdLine("a\1b \0 c\vd\f") == @["a\1b", "\0", "c\vd\f"]
    doAssert parseCmdLine("\1") == @["\1"]
  else:
    doAssert parseCmdLine("a\1b \0") == @["a\1b", "\0"]
