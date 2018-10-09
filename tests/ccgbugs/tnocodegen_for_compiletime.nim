# bug #1679
import macros, tables, hashes
proc hash(v: NimNode): Hash = 4  # performance is for suckers
macro test(body: untyped): typed =
  var a = initCountTable[NimNode]()
  a.inc(body)

test:
  1 + 1
