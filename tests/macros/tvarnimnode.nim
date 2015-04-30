discard """
  output: 10
"""

#bug #926

import macros

proc test(f: var NimNode) {.compileTime.} =
  f = newNimNode(nnkStmtList)
  f.add newCall(newIdentNode("echo"), newLit(10))

macro blah(prc: stmt): stmt =
  result = prc

  test(result)

proc test() {.blah.} =
  echo 5
