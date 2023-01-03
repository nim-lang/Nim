discard """
  matrix: "--experimental:codeReordering"
"""

runnableExamples:
  import strtabs
  var t = newStringTable()
  t["name"] = "John"
  t["city"] = "Monaco"
  doAssert t.len == 2
  doAssert t.hasKey "name"
  doAssert "name" in t

include "system/inclrtl"

{.pragma: rtlFunc, rtl.}

proc hasKey*(): bool {.rtlFunc.} =
  discard