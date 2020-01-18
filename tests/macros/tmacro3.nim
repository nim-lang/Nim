discard """
  output: ""
"""

import  macros

type
    TA = tuple[a: int]
    PA = ref TA

macro test*(a: untyped): untyped =
  var val: PA
  new(val)
  val.a = 4

test:
  "hi"

macro test2*(a: untyped): untyped =
  proc testproc(recurse: int) =
    echo "That's weird"
    var o : NimNode = nil
    echo "  no its not!"
    o = newNimNode(nnkNone)
    if recurse > 0:
      testproc(recurse - 1)
  testproc(5)

test2:
  "hi"
