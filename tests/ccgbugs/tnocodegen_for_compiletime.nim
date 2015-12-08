discard """
  file: "tnocodegen_for_compiletime.nim"
"""
# bug #1679

import macros, tables, hashes

proc hash(v: NimNode): Hash = 4  # performance is for suckers
macro test(body: stmt): stmt {.immediate.} =
  var a = initCountTable[NimNode]()
  a.inc(body)

test:
  1 + 1
