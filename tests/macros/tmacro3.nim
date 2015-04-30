discard """
  output: ""
"""

import  macros

type
    TA = tuple[a: int]
    PA = ref TA

macro test*(a: stmt): stmt {.immediate.} =
  var val: PA
  new(val)
  val.a = 4

test:
  "hi"

macro test2*(a: stmt): stmt {.immediate.} =
  proc testproc(recurse: int) =
    echo "Thats weird"
    var o : NimNode = nil
    echo "  no its not!"
    o = newNimNode(nnkNone)
    if recurse > 0:
      testproc(recurse - 1)
  testproc(5)

test2:
  "hi"

